# Vault secret management

## Install helm chart
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

```shell
helm upgrade --install vault hashicorp/vault -n vault --create-namespace -f vault/vault-values.yaml
```

## Initialize vault
```shell
kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > helm/vault/cluster-keys.json
```
> Vault keys will be stored in the file `helm/vault/cluster-keys.json`

## Unseal Vault running

Retrieve unseal key from `helm/vault/cluster-keys.json` and store it in `VAULT_UNSEAL_KEY` environment variable
```shell
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" helm/vault/cluster-keys.json)
```

### Unseal a non replicated Vault
```shell
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
```

### Unseal replicated vault
This step is for a replicated vault only, otherwise skip it
```shell
kubectl exec -ti vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl exec -ti vault-0 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec -ti vault-1 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec -ti vault-2 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
```

## Vault login
After vault unseal, you must open the connexion with vault to be able to configure it

Retrieve root token from `helm/vault/cluster-keys.json` and store it in `VAULT_ROOT_TOKEN` environment variable
```shell
export VAULT_ROOT_TOKEN=$(jq -r ".root_token" helm/vault/cluster-keys.json)
```
Vault login
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- /bin/sh -- vault login vault login -no-print $VAULT_ROOT_TOKEN
```

## Configure vault

### Create new secrets path
#### Enable kv-v2 secrets at the path secrets.
```shell
# replace PUT_YOUR_SECRET_PATH by your secret path name to create
kubectl exec --stdin=true --tty=true vault-0 -n vault -- vault secrets enable -path=PUT_YOUR_SECRET_PATH kv-v2
```

### Kubernetes authentication
Configure the Kubernetes authentication method to use the location of the Kubernetes API.

#### Enable the Kubernetes auth method
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault auth enable -path k3s kubernetes
```

#### Configure the Kubernetes authentication
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault write auth/k3s/config kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443
```

#### Distant cluster
> Run these following commands in the distant cluster that contains the installed project

```shell
#echo $(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)
#echo $(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}') > vault/creds/kubernetes-host
```

```shell
#export KUBERNETES_HOST=$(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}')# replace ${KUBERNETES_CA} by the content of vault/creds/kubernetes-ca
#export KUBERNETES_CA=$(kubectl -n vault-auth get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 -d; echo)
#
#vault write auth/k3s/config \
#  kubernetes_host="${KUBERNETES_HOST}" \
#  kubernetes_ca_cert="${KUBERNETES_CA}" \
#  disable_issuer_verification=true \
#  disable_local_ca_jwt="true"
```

### Create policy
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault policy write k3s-policy - <<EOF
        path "secrets/data/webapp/config" {
          capabilities = ["list", "read"]
        }
        path "secrets/metadata/webapp/config" {
          capabilities = ["list", "read"]
        }
EOF
```

### Create role
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault write auth/k3s/role/demo \
    bound_service_account_names=vault-account \
    bound_service_account_namespaces=my-ns \
    policies=k3s-policy \
    audience=vault \
    ttl=24h
```

### Create a secret
In this example
* secrets is the namespace
* webapp is the project name
* config is the env name
* username and password are the environment variables
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault kv put secrets/webapp/config username="static-user" password="static-password"

# Display secrets (optional)
kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
  vault kv get secrets/webapp/config
```

## UI Access

https://vault.k3s.localhost/

## Vault Secret Operator
### Install
```shell
helm upgrade --install vault-secrets-operator hashicorp/vault-secrets-operator -f vault/vault-operator-values.yaml -n vault-secrets-operator-system --create-namespace
```

### Deploy and sync a secret
#### Create namespace
```shell
kubectl create namespace my-ns
```
#### Create cluster role binding
```shell
kubectl apply -f vault/manifests/00-cluster-binding.yaml
```

#### Set up Kubernetes authentication
```shell
kubectl apply -f vault/manifests/01-vault-connexion.yaml
kubectl apply -f vault/manifests/02-vault-auth.yaml
```
#### Create the secret
```shell
kubectl apply -f vault/manifests/03-vault-static-secret.yaml
```

### Launch a web application

```shell
kubectl apply -f vault/04-webapp.yaml
```
To be sure the secrets are successfully synchronized, connect to alpine container and execute `printenv`.
You should show your secrets displayed.

TODO: Create webapp with ui to show secrets.

## References
https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-consul

https://www.sfeir.dev/cloud/simplifier-la-gestion-des-secrets-avec-vault-secret-operator/

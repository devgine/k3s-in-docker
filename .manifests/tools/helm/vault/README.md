# Vault

## Vault Secret Server

### Install helm chart
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

```shell
helm upgrade --install vault hashicorp/vault -n vault --create-namespace -f vault/vault-values.yaml
```

### Initialize vault
```shell
kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault/cluster-keys.json
```
> Vault keys will be stored in the file `vault/cluster-keys.json`

### Unseal Vault running
```shell
# replace $VAULT_UNSEAL_KEY by the value of unseal_keys_b64 in the file vault/cluster-keys.json
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
```

### Automation unseal replicated vault
```shell
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)

kubectl exec -ti vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl exec -ti vault-0 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec -ti vault-1 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec -ti vault-2 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
```

## Configure vault

### Connect to vault container
```shell
kubectl exec --stdin=true --tty=true vault-0 -n vault -- /bin/sh
vault login # use the value of root_token in the file vault/cluster-keys.json
```

### Enable kv-v2 secrets at the path secrets.
```shell
vault secrets enable -path=secrets kv-v2
```

### Enable the Kubernetes auth method
```shell
vault auth enable -path k3s kubernetes
```

### Configure the Kubernetes authentication
Configure the Kubernetes authentication method to use the location of the Kubernetes API.
#### Local cluster
```shell
vault write auth/k3s/config kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443
```

#### Distant cluster
> Run these following commands in the distant cluster that contains the installed project

```shell
echo $(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)
echo $(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}') > vault/creds/kubernetes-host
```

```shell
# replace ${KUBERNETES_HOST} by the content of vault/creds/kubernetes-host
# replace ${KUBERNETES_CA} by the content of vault/creds/kubernetes-ca
vault write auth/k3s/config \
  kubernetes_host="${KUBERNETES_HOST}" \
  kubernetes_ca_cert="${KUBERNETES_CA}" \
  disable_issuer_verification=true \
  disable_local_ca_jwt="true"
```

### Create policy
```shell

vault policy write k3s-policy - <<EOF
path "secrets/data/webapp/config" {
  capabilities = ["create", "list", "read", "update"]
}
EOF
#path "secrets/metadata/*" {
#  capabilities = ["list", "read"]
#}
```

### Create role
```shell
vault write auth/k3s/role/demo \
  bound_service_account_names=vault-account \
  bound_service_account_namespaces=my-ns \
  policies=k3s-policy \
  audience=vault \
  ttl=24h
```

### Create a secret
In this example
* webapp is the project name
* config is the env name
* username and password are the environment variables
```shell
vault kv put secrets/webapp/config username="static-user" password="static-password"
# Display
vault kv get secrets/webapp/config
exit
```

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

## Launch a web application

```shell
kubectl apply -f vault/04-webapp.yaml
```
To be sure the secrets are successfully synchronized, connect to alpine container and execute `printenv`.
You should show your secrets displayed.

TODO: Create webapp with ui to show secrets.

## UI Access

https://vault.k3s.localhost/

## References
https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-consul

https://www.sfeir.dev/cloud/simplifier-la-gestion-des-secrets-avec-vault-secret-operator/

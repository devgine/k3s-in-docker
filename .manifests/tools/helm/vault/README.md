# Vault secret management

## Install helm chart
Connect to k8s container
```shell
make shell
```
Add hashicorp repository
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```
Install Vault application
```shell
helm upgrade --install vault hashicorp/vault -n vault --create-namespace -f helm/vault/vault-values.yaml
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
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl exec vault-0 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec vault-1 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
kubectl exec vault-2 -- vault operator unseal "$VAULT_UNSEAL_KEY" -n vault
```

## Vault login
After vault unseal, you must open the connexion with vault to be able to configure it

Retrieve root token from `helm/vault/cluster-keys.json` and store it in `VAULT_ROOT_TOKEN` environment variable
```shell
export VAULT_ROOT_TOKEN=$(jq -r ".root_token" helm/vault/cluster-keys.json)
```
Vault login
```shell
kubectl exec vault-0 -n vault -- vault login -no-print $VAULT_ROOT_TOKEN
```

## Configure vault

### Create new secrets path
#### Enable kv-v2 secrets at the path secrets.
```shell
# replace PUT_YOUR_SECRET_PATH by your secret path name to create (exp: -path=mysecrets)
kubectl exec vault-0 -n vault -- vault secrets enable -path=PUT_YOUR_SECRET_PATH kv-v2
```

### Create policy
```shell
kubectl exec vault-0 -n vault -- vault policy write secrets-policy - <<EOF
path "secrets/data/preprod" {
  capabilities = ["list", "read"]
}
path "secrets/metadata/preprod" {
  capabilities = ["list", "read"]
}
EOF
```

### Create a secret
In this example
* secrets is the namespace
* preprod is the env name
* username and password are the environment variables
```shell
kubectl exec vault-0 -n vault -- \
  vault kv put secrets/preprod username="static-user" password="static-password"

# Display secrets (optional)
kubectl exec vault-0 -n vault -- \
  vault kv get secrets/preprod
```

## UI Access

https://vault.k3s.localhost/

## What's next ?

Now you can install either Vault operator or External secrets operator to sync secrets in your kubernetes cluster.
* [Install External secrets operator](external-secrets/README.md)
* [Install Vault operator](vault-operator/README.md)

## References
https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-consul

https://www.sfeir.dev/cloud/simplifier-la-gestion-des-secrets-avec-vault-secret-operator/

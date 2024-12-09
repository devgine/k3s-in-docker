# Vault operator

## Kubernetes authentication
Configure the Kubernetes authentication method to use the location of the Kubernetes API.

### Enable the Kubernetes auth method
```shell
kubectl exec vault-0 -n vault -- \
  vault auth enable -path local kubernetes
```

### Configure the Kubernetes authentication
```shell
kubectl exec -ti vault-0 -n vault -- sh
vault write auth/local/config kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443
exit
```

## Create policy
```shell
kubectl exec vault-0 -n vault -- vault policy write local-policy - <<EOF
path "secrets/data/preprod" {
  capabilities = ["list", "read"]
}
path "secrets/metadata/preprod" {
  capabilities = ["list", "read"]
}
EOF
```

## Create role
```shell
kubectl exec vault-0 -n vault -- \
  vault write auth/local/role/demo \
    bound_service_account_names=vault-operator-account \
    bound_service_account_namespaces=vault-app \
    policies=local-policy \
    audience=vault \
    ttl=24h
```

## Vault Secret Operator
### Install
```shell
helm upgrade --install vault-secrets-operator hashicorp/vault-secrets-operator -f helm/vault/vault-operator/vault-operator-values.yaml -n vault-secrets-operator --create-namespace
```

## Deploy and sync a secret
### Create namespace
```shell
kubectl create namespace vault-app
```
### Create cluster role binding
```shell
kubectl apply -f helm/vault/vault-operator/manifests/00-role-binding.yaml
```

### Set up Kubernetes authentication
```shell
kubectl apply -f helm/vault/vault-operator/manifests/01-vault-connexion.yaml
kubectl apply -f helm/vault/vault-operator/manifests/02-vault-auth.yaml
```
### Create the secret
```shell
kubectl apply -f helm/vault/vault-operator/manifests/03-vault-static-secret.yaml
```
Check if the secret is created
```shell
kubectl describe secrets vault-secrets-operator-kubernetes -n vault-app
```

## Launch a web application

```shell
kubectl apply -f helm/vault/vault-operator/04-webapp.yaml
```
To be sure the secrets are successfully synchronized, connect to alpine container and execute `printenv`.
You should show your secrets displayed.

TODO: Create webapp with ui to show secrets.

## References
https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-consul

https://www.sfeir.dev/cloud/simplifier-la-gestion-des-secrets-avec-vault-secret-operator/

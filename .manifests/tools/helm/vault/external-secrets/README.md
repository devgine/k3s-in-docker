# External Secret

## About
External secrets is an operator that synchronize kubernetes secrets from an external secrets management

## Install helm chart
```shell
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

```shell
helm upgrade -i --create-namespace -n external-secrets external-secrets external-secrets/external-secrets --set installCRDs=true
```

## [Option 1] Configure Vault using token
### Create Vault auth token
This token will be needed to communicate with vault by API from distant client
```shell
kubectl exec --stdin=true vault-0 -n vault -- vault policy write auth-token - <<EOF
path "*" {
  capabilities = ["list", "read"]
}
EOF
```
> You may replace `*` by your secrets path

```shell
kubectl exec --stdin=true vault-0 -n vault -- vault token create -policy=auth-token -format=json > helm/vault/token.json
```

## Create a Cluster Secret Store
Use the created auth-token to access to vault API
```shell
kubectl create secret generic vault-token -n vault-app --from-literal=token=PUT_YOUR_GENERATED_TOKEN_HERE
```

```shell
kubectl apply -f helm/vault/external-secrets/01-secret-store-token.yaml
kubectl get secretstore -n vault-app
kubectl apply -f helm/vault/external-secrets/02-external-secrets-token.yaml
kubectl get externalsecret -n vault-app
```

Check secrets 
```shell
kubectl get secret -n vault-app
```
The secret `vault-secrets` should be created.

## [option 2] Configure Vault using kubernetes auth

### Enable the Kubernetes auth method
```shell
kubectl exec vault-0 -n vault -- \
  vault auth enable -path k3s kubernetes
```
### Create k3s policy
```shell
kubectl exec --stdin=true vault-0 -n vault -- vault policy write k3s-policy - <<EOF
path "*" {
  capabilities = ["list", "read"]
}
EOF
```

### Configure the Kubernetes authentication
```shell
kubectl exec -ti vault-0 -n vault -- sh
vault write auth/k3s/config kubernetes_host=https://$KUBERNETES_PORT_443_TCP_ADDR:443
exit
```

### Create role
```shell
kubectl exec vault-0 -n vault -- \
  vault write auth/k3s/role/demo \
    bound_service_account_names=vault-account \
    bound_service_account_namespaces=vault-app \
    policies=k3s-policy \
    audience='' \
    ttl=24h
```

### Configure kubernetes
```shell
kubectl apply -f helm/vault/external-secrets/03-role-binding.yaml
```
```shell
kubectl apply -f helm/vault/external-secrets/04-secret-store-kubernetes.yaml
kubectl get secretstore vault-secret-store-kubernetes -n vault-app
kubectl apply -f helm/vault/external-secrets/05-external-secrets-kubernetes.yaml
kubectl get externalsecret vault-external-secret-kubernetes -n vault-app
```

Check secrets
```shell
kubectl get secret -n vault-app
```
The secret `vault-secrets-kubernetes` should be created.

> **Important**<br>
> Don't forget to add checksum annotation that contains the used secret to the deployment => to restart containers and retrieve new secrets when they are updated.<br>
> OR configure https://github.com/stakater/Reloader

## References
https://external-secrets.io/latest/provider/hashicorp-vault/
https://external-secrets.io/latest/provider/hashicorp-vault/#getting-multiple-secrets
https://www.digitalocean.com/community/tutorials/how-to-access-vault-secrets-inside-of-kubernetes-using-external-secrets-operator-eso
https://external-secrets.io/latest/guides/all-keys-one-secret/

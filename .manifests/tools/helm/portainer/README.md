# Portainer

## Install

### Connect to k8s console
```shell
make shell
```
Add portainer chart to local repositories
```shell
helm repo add portainer https://portainer.github.io/k8s/
```
Update local repositories
```shell
helm repo update
```
Install portainer
```shell
helm upgrade -f helm/portainer/value.yaml --install --create-namespace -n portainer portainer portainer/portainer
```

## Access

After installation the portainer dashboard will be accessible by https://portainer.k3s.localhost

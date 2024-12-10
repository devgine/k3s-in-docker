# k3s cluster

## About
This repository helps you create a kubernetes cluster locally with [k3s](https://docs.k3s.io/) using `Docker` and `traefik`.<br>
Also it contains all useful utils to manage kubernetes cluster like `kubectl`, `helm` and more

## Requirements
* git
* docker
* docker compose
* make

## How to

### Install traefik

First, install traefik stack from this repository https://github.com/devgine/traefik

### Clone the project
```shell
git clone git@github.com:devgine/k3s-traefik.git
```

### Run containers
```shell
make run
```

Enjoy ! 🥳

### Traefik dashboard

> https://traefik.k3s.localhost/

## K8S tools
To manage kubernetes resources in the cluster, you can connect to the k8s container and run kubectl or helm commands.<br>
This container contains the necessary tools to manage kubernetes cluster.

```shell
make shell
```

Below is an example to install nginx. You should run it inside the k8s container.
```shell
kubectl apply -f 00-nginx.yaml
```
Visit http://nginx.k3s.localhost

## Ingress nginx controller
By default, traefik is installed as an ingress reverse proxy, if you want to allow ingress nginx follow the following instructions

Create namespace
```shell
kubectl create ns ingress-nginx
```
Add the helm ingress repository
```shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```
Install nginx ingress controller
```shell
helm install ingress-nginx ingress-nginx/ingress-nginx -f values.yml -n ingress-nginx
```
## Routing
Router >> *.k3s.localhost >> Docker Traefik >> K3S container >> Ingress (traefik OR nginx) >> Service

## K3S config directories

| Node   | Directory                             | Description                                                                                                                                                    |
|--------|---------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Server | /output                               | k3s will generate a kubeconfig.yaml in this directory.                                                                                                         |
| Server | /var/lib/rancher/k3s/server/manifests | This directory is where you put all the (yaml) configuration files of the Kubernetes resources.                                                                |
| Agent  | /var/lib/rancher/k3s/agent/images     | this is where you would place an alternative traefik image (saved as a .tar file with'docker save'), if you want to use it, instead of the traefik:v3.1 image. |

## Available apps
* [Install Portainer](.manifests/tools/helm/portainer/README.md)
* [Install Vault](.manifests/tools/helm/vault/README.md)

## References
https://github.com/its-knowledge-sharing/K3S-Demo/blob/production/docker-compose.yaml<br>
https://docs.k3s.io/cli/server<br>
https://thenets.org/how-to-create-a-k3s-cluster-with-nginx-ingress-controller/<br>
https://blog.stephane-robert.info/post/homelab-ingress-k3s-certificats-self-signed/

### Addons
https://github.com/its-knowledge-sharing/K3S-Demo-Addons

### Custom coredns
https://github.com/owncloud/docs-ocis/issues/716<br>
https://learn.microsoft.com/en-us/azure/aks/coredns-custom#hosts-plugin

## ISSUES
https://github.com/k3s-io/k3s/issues/11165<br>
https://github.com/k3s-io/k3s/issues/11173

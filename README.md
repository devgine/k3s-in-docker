# k3s cluster

## About
This repository helps you deploy a kubernetes cluster locally using [k3s](https://docs.k3s.io/)

## Requirements
* git
* docker
* docker compose
* make

## How to

### Install traefik

First, install traefik stack from this repository https://github.com/devgine/stack

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
To install kubernetes resources in the cluster, you can connect to the k8s container and run kubectl or helm commands.

```shell
make shell
```
This container is configured to consume the installed k3s cluster's kubernetes API server.

Below is an example to install nginx.
```shell
kubectl apply -f 00-nginx.yaml
```
Visit http://nginx.k3s.localhost

## Routing
Router >> *.k3s.localhost >> Docker Traefik >> K3S Traefik >> Service

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
https://github.com/owncloud/docs-ocis/issues/716
https://learn.microsoft.com/en-us/azure/aks/coredns-custom#hosts-plugin

## ISSUES
https://github.com/k3s-io/k3s/issues/11165<br>
https://github.com/k3s-io/k3s/issues/11173

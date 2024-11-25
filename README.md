# k3s cluster

## About
This repository helps you deploy a kubernetes cluster locally using [k3s](https://docs.k3s.io/)

## Requirements
* git
* docker
* docker compose
* make

## How to

### Clone the project
```shell
git clone git@bitbucket.org:op-connect/k3s.git
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

## References
https://docs.k3s.io/cli/server<br>
https://thenets.org/how-to-create-a-k3s-cluster-with-nginx-ingress-controller/<br>
https://blog.stephane-robert.info/post/homelab-ingress-k3s-certificats-self-signed/

## ISSUES
https://github.com/k3s-io/k3s/issues/11165<br>
https://github.com/k3s-io/k3s/issues/11173

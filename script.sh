#!/bin/bash

#minikube setup
eval $(minikube docker-env) # set minikube to work with local images
minikube start
minikube addons enable ingress # enable ingress in minikube

# build docker images on minikube registry
docker build -t redis-server:latest -f docker/Dockerfile-redis .
docker build -t go-server:latest -f docker/Dockerfile-go data

docker images

# Generate TLS certs
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=myapp.local"
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key

# Add minikube IP to local /etc/hosts file, using this seeting we could access our app from browser
minikube_ip=$(minikube ip)
#echo "$minikube_ip myapp.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# create redis / go-server deployment
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/go-server-deployment.yaml



sudo minikube tunnel
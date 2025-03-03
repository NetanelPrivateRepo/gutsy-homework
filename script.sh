#!/bin/bash

# build docker images on minikube registry
docker build -t redis-server:latest -f docker/Dockerfile-redis .
docker build --no-cache -t go-server:latest -f docker/Dockerfile-go data

docker images
sleep 5

# Generate TLS certs
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=myapp.local"
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key

# Add minikube IP to local /etc/hosts file, using this seeting we could access our app from browser
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# create redis / go-server deployment
kubectl replace -f k8s/secret.yaml --force
sleep 5
kubectl replace -f k8s/redis-deployment.yaml --force
sleep 5
kubectl replace -f k8s/go-server-deployment.yaml --force

sudo minikube tunnel
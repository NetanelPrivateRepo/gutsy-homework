#!/bin/bash

# set minikube to work with local images
eval $(minikube docker-env)

minikube start

# build docker images on minikube registry
docker build -t redis-server:latest -f docker/Dockerfile-redis data
docker build -t go-server:latest -f docker/Dockerfile-go data

docker images

# create redis / go-server deployment
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/go-server-deployment.yaml

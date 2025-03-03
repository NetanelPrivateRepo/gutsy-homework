#!/bin/bash

# remove the deployments
kubectl delete -f k8s/secret.yaml
kubectl delete -f k8s/redis-deployment.yaml
kubectl delete -f k8s/go-server-deployment.yaml
kubectl delete secret my-tls-secret

# remove certs
rm tls*

# remove old conf files
rm data/redis.conf.bak
rm k8s/secret.yaml.bak

# clean /etc/hosts file, remove the map for myapp.local
sudo sed -i '' -e '$ d' /etc/hosts

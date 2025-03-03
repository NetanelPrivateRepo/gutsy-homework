#!/bin/bash

read -s -p "Enter new Redis password: " PASSWORD
echo ""

#minikube setup
eval $(minikube docker-env) # set minikube to work with local images
minikube start --driver=docker
minikube addons enable ingress # enable ingress in minikube

# Redis configuration file path
REDIS_CONF_PATH="./data/redis.conf"

if [[ -f "$REDIS_CONF_PATH" ]]; then
    # Update requirepass and ACL user password
    sed -i.bak -E "s/^requirepass .*/requirepass $PASSWORD/" "$REDIS_CONF_PATH"
    sed -i.bak -E "s|^user default on >.* allkeys allcommands|user default on >$PASSWORD allkeys allcommands|" "$REDIS_CONF_PATH"

    echo "✅ Redis conf file Updated $REDIS_CONF_PATH with new password."
else
    echo "Error: $REDIS_CONF_PATH not found!"
    exit 1
fi

# Encode the password in Base64
ENCODED_PASSWORD=$(echo -n "$PASSWORD" | base64)

# Update the password field in the secret YAML file
SECRET_FILE="k8s/secret.yaml"

if [[ -f "$SECRET_FILE" ]]; then
    sed -i.bak -E "s|^(  password: ).*|\1$ENCODED_PASSWORD|" "$SECRET_FILE"
    echo "✅ Secret file '$SECRET_FILE' updated successfully!"
else
    echo "❌ Error: Secret file '$SECRET_FILE' not found!"
    exit 1
fi

# build docker images on minikube registry
docker build -t redis-server:latest -f docker/Dockerfile-redis .
docker build -t go-server:latest -f docker/Dockerfile-go data

docker images

# Generate TLS certs
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=myapp.local"
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key

# Add minikube IP to local /etc/hosts file, using this seeting we could access our app from browser
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# create redis / go-server deployment
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/go-server-deployment.yaml

sudo minikube tunnel
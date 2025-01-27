#!/bin/bash

set -e

# Variables
MINIKUBE_VERSION="v1.29.0"
HELM_VERSION="v3.12.0"
KUBECTL_VERSION="v1.27.0"
NAMESPACE="database"
TF_DIR="./terraform"
MINIKUBE_CPU="4"
MINIKUBE_MEMORY="8192"

# Function to install dependencies
install_dependencies() {
  echo "Updating system and installing required packages..."
  sudo apt-get update -y
  sudo apt-get install -y curl git wget unzip apt-transport-https gnupg software-properties-common

  # Check if Docker is already installed
  if ! command -v docker &>/dev/null; then
    echo "Installing Docker..."
    sudo apt-get remove docker docker-engine docker.io containerd runc -y || true
    sudo apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  else
    echo "Docker is already installed."
  fi

  # Check if user is already in Docker group
  if ! groups $USER | grep -q "docker"; then
    echo "Adding current user to the Docker group..."
    sudo usermod -aG docker $USER
    echo "Re-login required to apply Docker group changes."
    echo "Please log out and back in, or run: 'newgrp docker'. Then re-run the script to continue."
    echo "Exiting script. Please follow the instructions and re-run the script."
    exit 0
  else
    echo "User is already in the Docker group."
  fi
}

# Function to install other tools
install_tools() {
  echo "Installing Minikube..."
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64
  sudo install minikube /usr/local/bin/
  rm minikube

  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install kubectl /usr/local/bin/

  echo "Installing Helm..."
  curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
  tar -xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz
  sudo install linux-amd64/helm /usr/local/bin/
  rm -rf linux-amd64 helm-${HELM_VERSION}-linux-amd64.tar.gz

  echo "Installing Terraform..."
  sudo apt install gnupg software-properties-common -y
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update
  sudo apt install terraform -y
}

# Function to start Minikube and enable the ingress addon
setup_minikube() {
  echo "Starting Minikube with Docker driver..."
  minikube start --driver=docker --cpus=${MINIKUBE_CPU} --memory=${MINIKUBE_MEMORY} --kubernetes-version=${KUBECTL_VERSION}

  echo "Enabling Nginx ingress controller..."
  minikube addons enable ingress
}

# Function to initialize Terraform and apply configurations
deploy_infrastructure() {
  echo "Initializing Terraform..."
  cd $TF_DIR
  terraform init

  echo "Applying Terraform configurations..."
  terraform apply -auto-approve

  cd -
}

# Function to verify SonarQube deployment
verify_deployment() {
  echo "Verifying SonarQube deployment..."
  kubectl get pods -n $NAMESPACE
  kubectl get svc -n $NAMESPACE
  kubectl get ingress -n $NAMESPACE
}

# Main script execution
echo "Starting the setup script..."

# Check if user has already run newgrp docker
if [[ "$USER" != "$(ps -o user= -p $PPID)" ]]; then
  echo "It seems you haven't run 'newgrp docker' or logged in again."
  echo "Please log out and log back in, or run: 'newgrp docker'. Then re-run this script."
  exit 0
fi

install_dependencies
install_tools
setup_minikube
deploy_infrastructure
verify_deployment

echo "SonarQube setup completed successfully!"

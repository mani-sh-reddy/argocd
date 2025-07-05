#!/bin/bash

repobase=$(git rev-parse --show-toplevel)
yellow='\033[1;33m'
reset='\033[0m'

echo "${yellow}=== Creating namespace 'argocd' if it doesn't exist ===${reset}"
kubectl create namespace argocd || true

echo "${yellow}=== Applying ArgoCD manifests ===${reset}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "${yellow}=== Run script to set ArgoCD admin password ===${reset}"
sh ${repobase}/bootstrap/apply-argocd-admin-pass.sh

echo "${yellow}=== Adding ArgoCD git repo config secrets ===${reset}"
kubectl apply -n argocd -f ${repobase}/bootstrap/secrets/secret-argocd-git-repo.yaml

# echo "${yellow}=== Adding SOPS GPG secret ===${reset}"
# kubectl apply -n argocd -f ${repobase}/bootstrap/secrets/secret-sops-gpg.yaml

echo "${yellow}=== Apply Apps (App of Apps) ===${reset}"
sh ${repobase}/bootstrap/apply-apps.sh

echo "${yellow}=== Create Port forward to ArgoCD web UI ===${reset}"
kubectl -n argocd port-forward service/argocd-server 8888:80 &

#!/bin/bash
kubectl apply -n argocd -f "$(git rev-parse --show-toplevel)/argocd.yaml"

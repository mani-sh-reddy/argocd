#!/bin/bash

set -e

# Check dependencies
if ! command -v htpasswd &>/dev/null; then
  echo "❌ 'htpasswd' not found. Install 'apache2-utils' or 'httpd-tools'."
  exit 1
fi

if ! command -v kubectl &>/dev/null; then
  echo "❌ 'kubectl' not found. Install it and configure your kube context."
  exit 1
fi

# Prompt for password
read -s -p "🔐 Enter new Argo CD admin password (or press enter to skip): " admin_pass
echo

# If no password is provided, exit
if [[ -z "$admin_pass" ]]; then
  echo "❌ No password provided. Exiting."
  exit 1
fi

# Hash the password using bcrypt
hashed_pass=$(htpasswd -nbBC 10 "" "$admin_pass" | tr -d ':\n' | sed 's/^$2y/$2a/')

# Get current UTC time
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Apply the secret directly using kubectl
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: argocd-secret
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-secret
    app.kubernetes.io/part-of: argocd
type: Opaque
stringData:
  admin.password: $hashed_pass
  admin.passwordMtime: "$timestamp"
EOF

echo "✅ Argo CD admin password updated and applied to the cluster."

kubectl -n argocd rollout restart deployment argocd-server
Run this:

```bash
kubectl edit configmap argocd-cm -n argocd
```


add this to exclude completely:

```yaml
data:
  resource.exclusions: |
    - apiGroups:
        - ""
      kinds:
        - PersistentVolume
        - PersistentVolumeClaim
      clusters:
        - "*"
```

add this to ignore:

```yaml
data:
  resource.customizations.ignoreResourceUpdates.PersistentVolumeClaim: |
    jsonPointers:
      - /status
      - /metadata/annotations
  resource.customizations.ignoreResourceUpdates.PersistentVolume: |
    jsonPointers:
      - /status
      - /spec/claimRef
      - /metadata/annotations
```
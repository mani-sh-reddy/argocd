# k8s

## Copying over files to PV (using PV debugger)

in the PV-DEBUGGER Yaml:
- change the permissions - should be same as app that is accessing it
- change the pvc you need to access

Stop current running pod that uses that specific PVC

Run PV-DEBUGGER pod
```sh
kubectl cp /Users/mani/Downloads/Imagined\ Life pv-debugger-8b94f484b-57hwx:/mnt/data
kubectl exec -it pv-debugger-7497f887d6-bqlq5 -- sh

```sh
kubectl exec -it pv-debugger -- apk add --no-cache rsync
kubectl exec -it pv-debugger -- rsync --version
```

### Copy using kubectl exec piping

```sh
rsync -av --progress ./my-bigfile.bin <(kubectl exec -i pv-debugger -- cat >/mnt/data/target-directory/my-bigfile.bin)
```


## immich restore

```sh
k -n immich port-forward services/immich-postgres-rw 5432:5432
```

```sh
PGPASSWORD="$(kubectl get secret immich-postgres-user -o jsonpath='{.data.password}' | base64 -d)" \
psql "host=localhost port=5432 dbname=immich user=immich-pg-user-adm sslmode=disable" \
-f /Users/mani/Downloads/immich-db-backup-20250804T020000-v1.137.3-pg14.18.sql
```

## force terminate namespace

```sh
(
NAMESPACE=your-rogue-namespace
kubectl proxy &
kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
)
```
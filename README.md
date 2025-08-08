Copying over files to PV

in the PV-DEBUGGER Yaml:
- change the permissions - should be same as app that is accessing it)
- change the pvc you need to access

Stop current running pod that uses that specific PVC

Run PV-DEBUGGER pod

kubectl cp /Users/mani/Downloads/Imagined\ Life pv-debugger-8b94f484b-57hwx:/mnt/data

kubectl exec -it pv-debugger-7497f887d6-bqlq5 -- sh


---

kubectl exec -it pv-debugger -- apk add --no-cache rsync
kubectl exec -it pv-debugger -- rsync --version  # verify

# Copy using kubectl exec piping
rsync -av --progress ./my-bigfile.bin <(kubectl exec -i pv-debugger -- cat >/mnt/data/target-directory/my-bigfile.bin)

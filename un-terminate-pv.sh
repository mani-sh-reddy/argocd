#!/bin/bash
set -euo pipefail
BACKUP_DIR="./pv-backups-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Finding PVs in Terminating state..."
mapfile -t PVs < <(kubectl get pv --no-headers | awk '$5=="Terminating"{print $1}')
if [ ${#PVs[@]} -eq 0 ]; then
echo "No PVs in Terminating state found."
exit 0
fi
echo "Will process the following PVs:"
printf ' - %s\n' "${PVs[@]}"
for PV in "${PVs[@]}"; do
echo "=== Processing PV: $PV ==="
RAW_JSON="$(kubectl get pv "$PV" -o json)"
echo "$RAW_JSON" > "$BACKUP_DIR/${PV}.original.json"
RECLAIM_POLICY=$(echo "$RAW_JSON" | jq -r '.spec.persistentVolumeReclaimPolicy // ""')
if [ "$RECLAIM_POLICY" != "Retain" ]; then
echo "WARNING: PV $PV has reclaimPolicy=$RECLAIM_POLICY (not Retain). Backend might be deleted by its controller upon PV deletion. Aborting this PV."
continue
fi
echo "Attempting to remove deletionTimestamp via replace..."
CLEAN_JSON="$(echo "$RAW_JSON" | jq 'del(.metadata.deletionTimestamp, .metadata.deletionGracePeriodSeconds)')"
echo "$CLEAN_JSON" > "$BACKUP_DIR/${PV}.clean.json"
set +e
echo "$CLEAN_JSON" | kubectl replace -f - 1>/dev/null 2>"$BACKUP_DIR/${PV}.replace.err"
REPLACE_RC=$?
set -e
if [ $REPLACE_RC -eq 0 ]; then
echo "Successfully replaced PV $PV without deletionTimestamp."
continue
fi
echo "Replace failed for $PV. Falling back to safe recreate of the PV object (data preserved due to Retain)."
echo "Error was:"
sed -n '1,120p' "$BACKUP_DIR/${PV}.replace.err"
if ! command -v yq >/dev/null 2>&1; then
echo "yq not found. Please install yq or use the jq-only fallback script. Skipping $PV."
continue
fi
RECREATE_JSON="$(echo "$RAW_JSON" |
jq '{
apiVersion: .apiVersion,
kind: .kind,
metadata: {
name: .metadata.name,
labels: .metadata.labels,
annotations: .metadata.annotations,
finalizers: .metadata.finalizers
},
spec: .spec
}')"
RECREATE_JSON="$(echo "$RECREATE_JSON" | jq 'del(.metadata.deletionTimestamp, .metadata.deletionGracePeriodSeconds)')"
echo "$RECREATE_JSON" | yq -P > "$BACKUP_DIR/${PV}.recreate.yaml"
echo "Deleting PV object $PV from API (backend preserved by Retain)..."
set +e
kubectl delete pv "$PV" --wait=false 1>/dev/null
for i in {1..30}; do
if ! kubectl get pv "$PV" >/dev/null 2>&1; then
break
fi
sleep 1
done
if kubectl get pv "$PV" >/dev/null 2>&1; then
echo "PV $PV still exists; deletion blocked by finalizers. Since policy is Retain, you can remove ONLY controller/protection finalizers to clear API deletion, but do so at your own risk."
echo "To proceed manually, consider: kubectl patch pv $PV --type json --patch='[{"op":"remove","path":"/metadata/finalizers"}]'"
echo "Skipping recreate for $PV."
set -e
continue
fi
set -e
echo "Recreating PV $PV object from saved manifest..."
kubectl apply -f "$BACKUP_DIR/${PV}.recreate.yaml"
echo "PV $PV recreated. If its PVC still exists and matches, it should re-bind automatically."
done
echo "Done. Backups and manifests saved under: $BACKUP_DIR"
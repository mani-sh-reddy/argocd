# immich restore

PGPASSWORD="$(kubectl get secret immich-postgres-user -o jsonpath='{.data.password}' | base64 -d)" \
psql "host=localhost port=5432 dbname=immich user=immich-pg-user-adm sslmode=disable" \
-f /Users/mani/Downloads/immich-db-backup-20250804T020000-v1.137.3-pg14.18.sql
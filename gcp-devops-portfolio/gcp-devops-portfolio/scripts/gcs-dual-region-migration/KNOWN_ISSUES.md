# Known issues encountered during dual-region GCS migration

## 1. CMEK/KMS mismatch on bucket recreation
**Symptom:** `gcloud storage buckets create` failed with a permission
error on `--default-encryption-key` even though the caller had
`roles/cloudkms.admin`.
**Cause:** The GCS service agent for the *project*, not the calling
user, needs `roles/cloudkms.cryptoKeyEncrypterDecrypter` on the key.
**Fix:**
```bash
gsutil kms serviceaccount -p "$PROJECT_ID"
gcloud kms keys add-iam-policy-binding "$KEY_NAME" \
  --keyring="$KEYRING" --location="$LOCATION" \
  --member="serviceAccount:$(gsutil kms serviceaccount -p "$PROJECT_ID")" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"
```

## 2. `gsutil --pap` CLI defect
**Symptom:** `gsutil mb --pap enforced` silently ignored the flag on
some `gsutil` versions, leaving Public Access Prevention off.
**Fix:** Set PAP explicitly as a follow-up call instead of relying on
the create-time flag:
```bash
gcloud storage buckets update "gs://$BUCKET" --public-access-prevention
```

## 3. Storage Transfer Service permission issues
**Symptom:** Transfer job stuck in `IN_PROGRESS` with 0 bytes copied.
**Cause:** STS uses a per-project service agent
(`project-<PROJECT_NUMBER>@storage-transfer-service.iam.gserviceaccount.com`)
that must have `roles/storage.objectAdmin` on **both** source and
destination buckets — granting it only on the destination is not
enough.
**Fix:**
```bash
for BUCKET in "$SOURCE_BUCKET" "$HOLDING_BUCKET"; do
  gsutil iam ch \
    serviceAccount:project-${PROJECT_NUMBER}@storage-transfer-service.iam.gserviceaccount.com:roles/storage.objectAdmin \
    "gs://$BUCKET"
done
```

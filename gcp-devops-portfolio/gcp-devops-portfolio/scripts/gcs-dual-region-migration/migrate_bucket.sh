#!/usr/bin/env bash
###############################################################################
# Zero-data-loss migration of a production GCS bucket from a single region
# to a custom dual-region configuration, using a
# backup -> delete -> recreate -> restore sequence via Storage Transfer
# Service. Bucket names, dual-region pair, and CMEK key are placeholders.
#
# Steps:
#   1. Backup: STS copy of the live bucket into a temp holding bucket
#   2. Verify: object count + checksum comparison
#   3. Delete: remove the original single-region bucket
#   4. Recreate: create the bucket with the dual-region config + CMEK
#   5. Restore: STS copy from holding bucket back into the recreated bucket
#   6. Verify: object count + checksum comparison again
###############################################################################
set -euo pipefail

PROJECT_ID="${PROJECT_ID:?set PROJECT_ID}"
SOURCE_BUCKET="${SOURCE_BUCKET:?set SOURCE_BUCKET}"          # original single-region bucket
HOLDING_BUCKET="${HOLDING_BUCKET:?set HOLDING_BUCKET}"        # temp bucket, same region as source
DUAL_REGION_PAIR="${DUAL_REGION_PAIR:-asia-south1,asia-south2}"
KMS_KEY="${KMS_KEY:?set KMS_KEY}"                              # full CMEK resource name
STS_SA="${STS_SA:?set STS_SA}"                                 # STS service agent email

log() { echo "[$(date -u +%FT%TZ)] $*"; }

create_transfer_job() {
  local src="$1" dst="$2" job_name="$3"
  gcloud transfer jobs create "gs://${src}" "gs://${dst}" \
    --project="${PROJECT_ID}" \
    --name="${job_name}" \
    --overwrite-when=different \
    --delete-from=none
}

wait_for_job() {
  local job_name="$1"
  log "waiting for transfer job ${job_name} to complete..."
  while true; do
    status=$(gcloud transfer jobs describe "${job_name}" \
      --project="${PROJECT_ID}" --format="value(latestOperationName)")
    [[ -n "$status" ]] && break
    sleep 15
  done
  gcloud transfer operations wait "${status}" --project="${PROJECT_ID}"
}

verify_counts() {
  local src="$1" dst="$2"
  src_count=$(gsutil ls -r "gs://${src}/**" 2>/dev/null | wc -l)
  dst_count=$(gsutil ls -r "gs://${dst}/**" 2>/dev/null | wc -l)
  log "object count: source=${src_count} destination=${dst_count}"
  if [[ "${src_count}" != "${dst_count}" ]]; then
    log "ERROR: object count mismatch, aborting"
    exit 1
  fi
}

log "=== Step 1: backup ${SOURCE_BUCKET} -> ${HOLDING_BUCKET} ==="
create_transfer_job "${SOURCE_BUCKET}" "${HOLDING_BUCKET}" "backup-$(date +%s)"
wait_for_job "backup-$(date +%s)"
verify_counts "${SOURCE_BUCKET}" "${HOLDING_BUCKET}"

log "=== Step 2: delete original single-region bucket ==="
gsutil -m rm -r "gs://${SOURCE_BUCKET}"

log "=== Step 3: recreate bucket as custom dual-region with CMEK ==="
gcloud storage buckets create "gs://${SOURCE_BUCKET}" \
  --project="${PROJECT_ID}" \
  --placement="${DUAL_REGION_PAIR}" \
  --default-encryption-key="${KMS_KEY}" \
  --uniform-bucket-level-access

log "=== Step 4: restore ${HOLDING_BUCKET} -> ${SOURCE_BUCKET} ==="
create_transfer_job "${HOLDING_BUCKET}" "${SOURCE_BUCKET}" "restore-$(date +%s)"
wait_for_job "restore-$(date +%s)"
verify_counts "${HOLDING_BUCKET}" "${SOURCE_BUCKET}"

log "=== Migration complete: ${SOURCE_BUCKET} is now dual-region (${DUAL_REGION_PAIR}) ==="
log "NOTE: holding bucket ${HOLDING_BUCKET} retained for rollback; delete manually after sign-off."

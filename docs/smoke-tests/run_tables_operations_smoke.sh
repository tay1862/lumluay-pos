#!/usr/bin/env bash
set -euo pipefail

# Tables operations smoke test runner
# Required env vars:
#   BASE_URL, TOKEN, TENANT_ID
#   TABLE_SOURCE, TABLE_TARGET, TABLE_MERGE_1, TABLE_MERGE_2
# Optional env vars:
#   SPLIT_ITEM_IDS (comma-separated UUID list)
#   CURL_BIN (default: curl)

CURL_BIN="${CURL_BIN:-curl}"

required=(
  BASE_URL
  TOKEN
  TENANT_ID
  TABLE_SOURCE
  TABLE_TARGET
  TABLE_MERGE_1
  TABLE_MERGE_2
)

for key in "${required[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "[ERROR] Missing env var: $key" >&2
    exit 1
  fi
done

API_BASE="${BASE_URL%/}"
AUTH_HEADER="Authorization: Bearer ${TOKEN}"
TENANT_HEADER="x-tenant-id: ${TENANT_ID}"
CT_HEADER="Content-Type: application/json"

call_api() {
  local method="$1"
  local path="$2"
  local payload="${3:-}"

  echo
  echo "==> ${method} ${path}"

  if [[ -n "$payload" ]]; then
    "$CURL_BIN" -sS -X "$method" "${API_BASE}${path}" \
      -H "$AUTH_HEADER" \
      -H "$TENANT_HEADER" \
      -H "$CT_HEADER" \
      -d "$payload"
  else
    "$CURL_BIN" -sS -X "$method" "${API_BASE}${path}" \
      -H "$AUTH_HEADER" \
      -H "$TENANT_HEADER"
  fi

  echo
}

# 0) Legacy zone alias quick checks
call_api "GET" "/zones"

# 1) Move table
move_payload=$(cat <<JSON
{"targetTableId":"${TABLE_TARGET}"}
JSON
)
call_api "POST" "/tables/${TABLE_SOURCE}/move" "$move_payload"

# 2) Merge (primary endpoint)
merge_payload=$(cat <<JSON
{"targetTableId":"${TABLE_TARGET}","mergeTableIds":["${TABLE_MERGE_1}","${TABLE_MERGE_2}"]}
JSON
)
call_api "POST" "/tables/merge" "$merge_payload"

# 3) Merge (compatibility endpoint)
merge_compat_payload=$(cat <<JSON
{"mergeTableIds":["${TABLE_MERGE_1}","${TABLE_MERGE_2}"]}
JSON
)
call_api "POST" "/tables/${TABLE_TARGET}/merge" "$merge_compat_payload"

# 4) Split table (optional if SPLIT_ITEM_IDS is provided)
if [[ -n "${SPLIT_ITEM_IDS:-}" ]]; then
  IFS=',' read -r -a raw_ids <<<"$SPLIT_ITEM_IDS"
  ids_json=""
  for id in "${raw_ids[@]}"; do
    trimmed="${id// /}"
    [[ -z "$trimmed" ]] && continue
    if [[ -n "$ids_json" ]]; then
      ids_json+=" ,"
    fi
    ids_json+="\"${trimmed}\""
  done

  if [[ -n "$ids_json" ]]; then
    split_payload=$(cat <<JSON
{"targetTableId":"${TABLE_TARGET}","orderItemIds":[${ids_json}]}
JSON
)
    call_api "POST" "/tables/${TABLE_SOURCE}/split" "$split_payload"
  else
    echo "[WARN] SPLIT_ITEM_IDS is set but no valid IDs were parsed. Skip split test."
  fi
else
  echo
  echo "[INFO] SPLIT_ITEM_IDS not set. Skip split test."
fi

# 5) QR code payload
call_api "GET" "/tables/${TABLE_TARGET}/qr-code"

# 6) Sanity snapshot
call_api "GET" "/tables"
call_api "GET" "/orders"

echo

echo "[DONE] Tables smoke tests finished"

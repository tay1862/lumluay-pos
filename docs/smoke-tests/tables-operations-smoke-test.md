# Tables Operations API Smoke Test Payloads

ใช้สำหรับทดสอบเร็วหลัง deploy ฟีเจอร์โต๊ะ: move/merge/split/qr

## Prerequisites

- Base URL: `https://<api-host>/v1`
- Header:
  - `Authorization: Bearer <access-token>`
  - `x-tenant-id: <tenant-uuid>`
  - `Content-Type: application/json`
- เตรียม table ids:
  - `TABLE_SOURCE`
  - `TABLE_TARGET`
  - `TABLE_MERGE_1`
  - `TABLE_MERGE_2`

## 1) Move Table

Endpoint:

`POST /tables/:id/move`

ตัวอย่าง:

```bash
curl -X POST "$BASE_URL/tables/$TABLE_SOURCE/move" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-tenant-id: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "targetTableId": "'$TABLE_TARGET'"
  }'
```

Expected:

- `moved: true`
- `sourceTableId`, `targetTableId`, `orderId`

## 2) Merge Tables (Primary Endpoint)

Endpoint:

`POST /tables/merge`

ตัวอย่าง:

```bash
curl -X POST "$BASE_URL/tables/merge" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-tenant-id: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "targetTableId": "'$TABLE_TARGET'",
    "mergeTableIds": ["'$TABLE_MERGE_1'", "'$TABLE_MERGE_2'"]
  }'
```

Expected:

- `merged: true`
- `baseOrderId`
- `mergedFromTableIds`
- `consumedOrderIds`

## 3) Merge Tables (Compatibility Endpoint)

Endpoint:

`POST /tables/:id/merge`

ตัวอย่าง:

```bash
curl -X POST "$BASE_URL/tables/$TABLE_TARGET/merge" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-tenant-id: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "mergeTableIds": ["'$TABLE_MERGE_1'", "'$TABLE_MERGE_2'"]
  }'
```

Expected:

- ผลลัพธ์เทียบเท่า `POST /tables/merge`

## 4) Split Table

Endpoint:

`POST /tables/:id/split`

เตรียม `ORDER_ITEM_IDS` จาก `GET /orders/:orderId` ของโต๊ะต้นทาง

```bash
curl -X POST "$BASE_URL/tables/$TABLE_SOURCE/split" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-tenant-id: $TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "targetTableId": "'$TABLE_TARGET'",
    "orderItemIds": [
      "<order-item-uuid-1>",
      "<order-item-uuid-2>"
    ]
  }'
```

Expected:

- `split: true`
- `sourceOrderId`
- `splitOrderId`
- `movedItemCount`

## 5) Table QR Code

Endpoint:

`GET /tables/:id/qr-code`

```bash
curl "$BASE_URL/tables/$TABLE_TARGET/qr-code" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-tenant-id: $TENANT_ID"
```

Expected:

- `url` และ `qrPayload` เช่น `https://menu.lumluay.com/<tenantSlug>/<tableId>`

## 6) Optional Sanity Checks

- เช็กสถานะโต๊ะหลัง operation:

```bash
curl "$BASE_URL/tables" -H "Authorization: Bearer $TOKEN" -H "x-tenant-id: $TENANT_ID"
```

- เช็ก order หลัง merge/split:

```bash
curl "$BASE_URL/orders" -H "Authorization: Bearer $TOKEN" -H "x-tenant-id: $TENANT_ID"
```

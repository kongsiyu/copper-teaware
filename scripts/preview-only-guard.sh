#!/usr/bin/env bash
# Verify that the Capsule Preview theme stays in preview-only + notify-only mode.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="${ROOT_DIR}/theme"
PRODUCT_TEMPLATE="${THEME_DIR}/templates/product-copper-kettle.liquid"
INDEX_TEMPLATE="${THEME_DIR}/templates/index.json"
HOMEPAGE_SECTION="${THEME_DIR}/sections/preview-homepage.liquid"
PRODUCT_SCHEMA="${THEME_DIR}/product-schema.json"

fail() {
  printf 'preview-only guard failed: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_file "$PRODUCT_TEMPLATE"
require_file "$INDEX_TEMPLATE"
require_file "$HOMEPAGE_SECTION"
require_file "$PRODUCT_SCHEMA"

grep -q 'data-sample-verified="{{ sample_verified }}"' "$PRODUCT_TEMPLATE" \
  || fail "PDP is missing sample_verified data marker"

grep -q 'data-preview-commerce="{% unless sample_verified %}notify-only' "$PRODUCT_TEMPLATE" \
  || fail "PDP is missing notify-only commerce marker"

grep -q 'data-structured-offers="{% unless sample_verified %}disabled' "$PRODUCT_TEMPLATE" \
  || fail "PDP is missing structured offer disable marker"

grep -q 'data-hidden-modules="price inventory purchase-buttons variants reviews recommendations delivery offers"' "$PRODUCT_TEMPLATE" \
  || fail "PDP does not explicitly list hidden commerce modules"

grep -q 'value="{{ notify_tag }}"' "$PRODUCT_TEMPLATE" \
  || fail "PDP customer form does not use the fixed notify tag"

grep -q "assign notify_tag = 'notify-copper-bottle-pour-over-kettle'" "$PRODUCT_TEMPLATE" \
  || fail "PDP notify tag is not fixed to the approved tag"

grep -q '资料图 / 占位图 / 待实拍' "$PRODUCT_TEMPLATE" \
  || fail "PDP is missing the approved media status badge"

grep -q '"tag_applied": "notify-copper-bottle-pour-over-kettle"' "${THEME_DIR}/config/analytics-email.json" \
  || fail "analytics/email config does not match the PDP notify tag"

grep -q 'id="notify-cta"' "$HOMEPAGE_SECTION" \
  || fail "homepage section is missing the notify-cta anchor"

grep -q 'value="{{ notify_tag }}"' "$HOMEPAGE_SECTION" \
  || fail "homepage customer form does not use the fixed notify tag"

grep -q "assign notify_tag = 'notify-copper-bottle-pour-over-kettle'" "$HOMEPAGE_SECTION" \
  || fail "homepage notify tag is not fixed to the approved tag"

grep -q '资料图 / 占位图 / 待实拍' "$HOMEPAGE_SECTION" \
  || fail "homepage is missing the approved media status badge"

if grep -Eq '"price": "__PENDING_PRICING__"|加入购物车|暂时缺货|预售成功|预约成功|候补成功|锁定库存|锁定名额' "$PRODUCT_TEMPLATE" "$INDEX_TEMPLATE" "$HOMEPAGE_SECTION" "$PRODUCT_SCHEMA"; then
  fail "found forbidden sale-state wording or price sentinel in preview files"
fi

python3 - "$INDEX_TEMPLATE" "$HOMEPAGE_SECTION" "$PRODUCT_SCHEMA" <<'PY'
import json
import sys

index_path, homepage_section_path, schema_path = sys.argv[1:4]
with open(index_path, "r", encoding="utf-8") as f:
    raw_index = f.read()
if raw_index.lstrip().startswith("/*"):
    end = raw_index.find("*/")
    if end != -1:
        raw_index = raw_index[end + 2 :]
index = json.loads(raw_index)
with open(homepage_section_path, "r", encoding="utf-8") as f:
    homepage_section = f.read()
with open(schema_path, "r", encoding="utf-8") as f:
    schema = json.load(f)

sections = index.get("sections", {})
order = index.get("order", [])
if order != ["preview-homepage"]:
    raise SystemExit("homepage must use only the Wokiee-compatible preview-homepage section")
if sections.get("preview-homepage", {}).get("type") != "preview-homepage":
    raise SystemExit("homepage preview section must be type preview-homepage")

required_homepage_markers = [
    "preview-home__status",
    "preview-home__hero",
    "preview-home__grid",
    "preview-home__artifact",
    "preview-home__research",
    "preview-home__faq",
    "preview-home__notify",
    "notify-cta",
    "/pages/preview-stage",
    "/pages/research-notes",
    "/pages/faq",
    "/products/copper-bottle-pour-over-kettle#notify-interest",
]
missing = [marker for marker in required_homepage_markers if marker not in homepage_section]
if missing:
    raise SystemExit(f"missing homepage preview markers: {', '.join(missing)}")

metafields = {
    (field.get("namespace"), field.get("key")): str(field.get("value")).lower()
    for field in schema.get("product", {}).get("metafields", [])
}
if metafields.get(("product_info", "sample_verified")) != "false":
    raise SystemExit("product schema must keep product_info.sample_verified=false")
if metafields.get(("product_info", "single_sku_locked")) != "true":
    raise SystemExit("product schema must keep product_info.single_sku_locked=true")

variants = schema.get("product", {}).get("variants", [])
if len(variants) != 1:
    raise SystemExit("product schema must remain single SKU")
variant = variants[0]
if str(variant.get("price")) != "0.00":
    raise SystemExit("draft product schema price must remain 0.00 until approved unlock")
if int(variant.get("inventory_quantity", -1)) != 0:
    raise SystemExit("draft product schema inventory_quantity must remain 0")

images = schema.get("product", {}).get("images", [])
if not images or "资料图" not in images[0].get("alt", ""):
    raise SystemExit("product image alt must identify the media as a reference image")
if "待实拍" not in images[0].get("status_badge", ""):
    raise SystemExit("product image status_badge must include 待实拍")
PY

printf 'preview-only guard passed\n'

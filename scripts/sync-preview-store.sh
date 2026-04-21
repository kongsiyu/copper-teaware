#!/usr/bin/env bash
# Sync the preview-only Shopify store setup via Admin API.
#
# This script is intentionally idempotent: it updates the main theme files,
# preview pages, navigation, draft product, variant SKU, and product metafields
# without publishing the product or enabling commerce modules.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
THEME_DIR="$ROOT_DIR/theme"
API_VERSION="${SHOPIFY_API_VERSION:-2025-01}"

PRODUCT_HANDLE="copper-bottle-pour-over-kettle"
PRODUCT_TITLE="Copper Pour-Over Kettle With a Bottle-Shaped Silhouette"
PRODUCT_TYPE="Coffeeware"
PRODUCT_TEMPLATE_SUFFIX="copper-kettle"
PUBLIC_PREVIEW_PAGE_HANDLE="copper-kettle-preview"
PUBLIC_PREVIEW_PAGE_TITLE="Product Details"
PUBLIC_PREVIEW_TEMPLATE_SUFFIX="copper-kettle-preview"
PRODUCT_SKU="CX-COFFEE-KETTLE-01"
PRODUCT_PRICE="0.00"
MATERIAL_NOTE="Copper body"

log() {
  printf '%s\n' "$*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
fi

: "${SHOPIFY_STORE_DOMAIN:?需要设置 SHOPIFY_STORE_DOMAIN 环境变量}"

SHOPIFY_CLIENT_ID="${SHOPIFY_CLIENT_ID:-${SHOPIFY_CLINET_ID:-}}"
SHOPIFY_CLIENT_SECRET="${SHOPIFY_CLIENT_SECRET:-${SHOPIFY_SECRET:-}}"
SHOPIFY_ADMIN_API_TOKEN="${SHOPIFY_ADMIN_API_TOKEN:-}"
SHOPIFY_STORE_DOMAIN="${SHOPIFY_STORE_DOMAIN#https://}"
SHOPIFY_STORE_DOMAIN="${SHOPIFY_STORE_DOMAIN#http://}"
SHOPIFY_STORE_DOMAIN="${SHOPIFY_STORE_DOMAIN%/}"
STOREFRONT_BASE_URL="https://${SHOPIFY_STORE_DOMAIN}"

request_token() {
  local client_id="$1"
  local client_secret="$2"

  curl -sS \
    -X POST "https://${SHOPIFY_STORE_DOMAIN}/admin/oauth/access_token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=client_credentials' \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}"
}

if [[ -n "$SHOPIFY_ADMIN_API_TOKEN" ]]; then
  access_token="$SHOPIFY_ADMIN_API_TOKEN"
  log "Auth: using SHOPIFY_ADMIN_API_TOKEN"
else
  : "${SHOPIFY_CLIENT_ID:?需要设置 SHOPIFY_CLIENT_ID（或兼容别名 SHOPIFY_CLINET_ID）环境变量}"
  : "${SHOPIFY_CLIENT_SECRET:?需要设置 SHOPIFY_CLIENT_SECRET（或兼容别名 SHOPIFY_SECRET）环境变量}"

  token_response="$(request_token "$SHOPIFY_CLIENT_ID" "$SHOPIFY_CLIENT_SECRET")"
  if ! printf '%s\n' "$token_response" | jq -e '.access_token' >/dev/null 2>&1; then
    log "Auth: configured client credentials failed; retrying swapped runtime mapping"
    token_response="$(request_token "$SHOPIFY_CLIENT_SECRET" "$SHOPIFY_CLIENT_ID")"
  fi

  access_token="$(printf '%s\n' "$token_response" | jq -r '.access_token // empty')"
  [[ -n "$access_token" ]] || die "Shopify token exchange failed: $(printf '%s\n' "$token_response" | jq -r '.error_description // .error // .errors // .message // tostring')"
  log "Auth: client credentials token exchange ok"
fi

graphql() {
  local query="$1"
  local variables="${2:-}"
  local payload
  local response
  local status
  local body

  if [[ -z "$variables" ]]; then
    variables='{}'
  fi

  payload="$(jq -cn --arg query "$query" --argjson variables "$variables" '{query: $query, variables: $variables}')"
  response="$(
    curl -sS -w '\n%{http_code}' \
      -X POST "https://${SHOPIFY_STORE_DOMAIN}/admin/api/${API_VERSION}/graphql.json" \
      -H 'Content-Type: application/json' \
      -H "X-Shopify-Access-Token: ${access_token}" \
      --data "$payload"
  )"
  status="$(printf '%s\n' "$response" | tail -n1)"
  body="$(printf '%s\n' "$response" | sed '$d')"

  if [[ "$status" != "200" ]]; then
    printf '%s\n' "$body" >&2
    die "GraphQL HTTP ${status}"
  fi

  printf '%s\n' "$body"
}

require_no_top_level_errors() {
  local response="$1"
  local label="$2"

  if [[ "$(printf '%s\n' "$response" | jq '(.errors // []) | length')" != "0" ]]; then
    log "${label} top-level errors:"
    printf '%s\n' "$response" | jq '.errors' >&2
    exit 1
  fi
}

require_no_user_errors() {
  local response="$1"
  local filter="$2"
  local label="$3"
  local count

  count="$(printf '%s\n' "$response" | jq "${filter} | length")"
  if [[ "$count" != "0" ]]; then
    log "${label} userErrors:"
    printf '%s\n' "$response" | jq "$filter" >&2
    exit 1
  fi
}

CURRENT_STATE_QUERY="$(cat <<'GRAPHQL'
query CurrentState($productHandle: String!) {
  shop {
    name
    myshopifyDomain
  }
  themes(first: 20, roles: [MAIN, UNPUBLISHED]) {
    nodes {
      id
      name
      role
    }
  }
  productByHandle(handle: $productHandle) {
    id
    handle
    title
    status
    templateSuffix
    productType
    tags
    descriptionHtml
    metafields(first: 20, namespace: "product_info") {
      nodes {
        id
        namespace
        key
        type
        value
      }
    }
    variants(first: 10) {
      nodes {
        id
        sku
        price
        inventoryQuantity
        inventoryPolicy
        inventoryItem {
          id
          sku
          tracked
          requiresShipping
        }
      }
    }
  }
  pages(first: 50) {
    nodes {
      id
      handle
      title
      templateSuffix
      isPublished
      updatedAt
    }
  }
  menus(first: 20) {
    nodes {
      id
      handle
      title
      items {
        id
        title
        type
        url
        resourceId
        tags
      }
    }
  }
}
GRAPHQL
)"

THEME_FILES_UPSERT_MUTATION="$(cat <<'GRAPHQL'
mutation UpsertPreviewThemeFiles($themeId: ID!, $files: [OnlineStoreThemeFilesUpsertFileInput!]!) {
  themeFilesUpsert(themeId: $themeId, files: $files) {
    upsertedThemeFiles {
      filename
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

PAGE_CREATE_MUTATION="$(cat <<'GRAPHQL'
mutation CreatePreviewPage($page: PageCreateInput!) {
  pageCreate(page: $page) {
    page {
      id
      handle
      title
      templateSuffix
      isPublished
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

PAGE_UPDATE_MUTATION="$(cat <<'GRAPHQL'
mutation UpdatePreviewPage($id: ID!, $page: PageUpdateInput!) {
  pageUpdate(id: $id, page: $page) {
    page {
      id
      handle
      title
      templateSuffix
      isPublished
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

PRODUCT_UPDATE_MUTATION="$(cat <<'GRAPHQL'
mutation UpdatePreviewProduct($product: ProductUpdateInput!) {
  productUpdate(product: $product) {
    product {
      id
      handle
      title
      status
      templateSuffix
      productType
      tags
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

VARIANT_UPDATE_MUTATION="$(cat <<'GRAPHQL'
mutation UpdatePreviewVariant($productId: ID!, $variants: [ProductVariantsBulkInput!]!) {
  productVariantsBulkUpdate(productId: $productId, variants: $variants) {
    productVariants {
      id
      sku
      price
      inventoryPolicy
      inventoryItem {
        sku
        tracked
        requiresShipping
      }
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

METAFIELDS_SET_MUTATION="$(cat <<'GRAPHQL'
mutation SetPreviewProductMetafields($metafields: [MetafieldsSetInput!]!) {
  metafieldsSet(metafields: $metafields) {
    metafields {
      id
      namespace
      key
      type
      value
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

SHOP_POLICY_UPDATE_MUTATION="$(cat <<'GRAPHQL'
mutation UpdatePreviewPrivacyPolicy($shopPolicy: ShopPolicyInput!) {
  shopPolicyUpdate(shopPolicy: $shopPolicy) {
    shopPolicy {
      id
      type
      title
      url
      updatedAt
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

MENU_CREATE_MUTATION="$(cat <<'GRAPHQL'
mutation CreatePreviewMenu($title: String!, $handle: String!, $items: [MenuItemCreateInput!]!) {
  menuCreate(title: $title, handle: $handle, items: $items) {
    menu {
      id
      handle
      title
      items {
        title
        type
        url
        resourceId
      }
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

MENU_UPDATE_MUTATION="$(cat <<'GRAPHQL'
mutation UpdatePreviewMenu($id: ID!, $title: String!, $handle: String!, $items: [MenuItemUpdateInput!]!) {
  menuUpdate(id: $id, title: $title, handle: $handle, items: $items) {
    menu {
      id
      handle
      title
      items {
        title
        type
        url
        resourceId
      }
    }
    userErrors {
      field
      message
    }
  }
}
GRAPHQL
)"

state_variables="$(jq -nc --arg handle "$PRODUCT_HANDLE" '{productHandle: $handle}')"
state="$(graphql "$CURRENT_STATE_QUERY" "$state_variables")"
require_no_top_level_errors "$state" 'current state query'

shop_name="$(printf '%s\n' "$state" | jq -r '.data.shop.name')"
shop_domain="$(printf '%s\n' "$state" | jq -r '.data.shop.myshopifyDomain')"
main_theme_id="$(printf '%s\n' "$state" | jq -r '.data.themes.nodes[]? | select(.role == "MAIN") | .id' | head -n1)"
main_theme_name="$(printf '%s\n' "$state" | jq -r '.data.themes.nodes[]? | select(.role == "MAIN") | .name' | head -n1)"
product_id="$(printf '%s\n' "$state" | jq -r '.data.productByHandle.id // empty')"
variant_id="$(printf '%s\n' "$state" | jq -r '.data.productByHandle.variants.nodes[0].id // empty')"

[[ -n "$main_theme_id" ]] || die "No MAIN theme found"
[[ -n "$product_id" ]] || die "Product ${PRODUCT_HANDLE} not found; create the draft product before running this sync"
[[ -n "$variant_id" ]] || die "Product ${PRODUCT_HANDLE} has no variant to update"

log "Shop: ${shop_name} (${shop_domain})"
log "Main theme: ${main_theme_name} (${main_theme_id})"
log "Product: ${PRODUCT_HANDLE} (${product_id})"

upsert_theme_files() {
  local files_json="$1"
  local label="$2"
  local response

  response="$(
    graphql "$THEME_FILES_UPSERT_MUTATION" \
      "$(jq -nc --arg themeId "$main_theme_id" --argjson files "$files_json" '{themeId: $themeId, files: $files}')"
  )"
  require_no_top_level_errors "$response" "$label"
  require_no_user_errors "$response" '.data.themeFilesUpsert.userErrors' "$label"
  printf '%s\n' "$response" | jq -r '.data.themeFilesUpsert.upsertedThemeFiles[].filename' | sed 's/^/  theme file: /' >&2
}

build_theme_files_json() {
  local payload='[]'
  local filename

  for filename in "$@"; do
    [[ -f "${THEME_DIR}/${filename}" ]] || die "Missing theme file: ${THEME_DIR}/${filename}"
    payload="$(
      jq -cn \
        --argjson files "$payload" \
        --arg filename "$filename" \
        --rawfile value "${THEME_DIR}/${filename}" \
        '$files + [{filename: $filename, body: {type: "TEXT", value: $value}}]'
    )"
  done

  printf '%s\n' "$payload"
}

log "Upserting preview theme support files"
upsert_theme_files \
  "$(build_theme_files_json \
    "snippets/preview-launch-theme.liquid" \
    "snippets/preview-page-shell.liquid" \
    "snippets/preview-product-dossier.liquid" \
    "sections/preview-homepage.liquid")" \
  'themeFilesUpsert support files'

log "Upserting preview theme templates"
upsert_theme_files \
  "$(build_theme_files_json \
    "templates/product-copper-kettle.liquid" \
    "templates/page.copper-kettle-preview.liquid" \
    "templates/page.preview-stage.liquid" \
    "templates/page.research-notes.liquid" \
    "templates/page.faq.liquid")" \
  'themeFilesUpsert templates'

log "Upserting preview homepage template"
upsert_theme_files \
  "$(build_theme_files_json "templates/index.json")" \
  'themeFilesUpsert index template'

ensure_page() {
  local handle="$1"
  local title="$2"
  local template_suffix="$3"
  local existing_id
  local page_input
  local response

  existing_id="$(printf '%s\n' "$state" | jq -r --arg handle "$handle" '.data.pages.nodes[]? | select(.handle == $handle) | .id' | head -n1)"
  page_input="$(
    jq -nc \
      --arg title "$title" \
      --arg handle "$handle" \
      --arg templateSuffix "$template_suffix" \
      '{title: $title, handle: $handle, body: "", isPublished: true, templateSuffix: $templateSuffix}'
  )"

  if [[ -n "$existing_id" ]]; then
    log "Updating page: ${handle}"
    response="$(
      graphql "$PAGE_UPDATE_MUTATION" \
        "$(jq -nc --arg id "$existing_id" --argjson page "$page_input" '{id: $id, page: $page}')"
    )"
    require_no_top_level_errors "$response" "pageUpdate ${handle}"
    require_no_user_errors "$response" '.data.pageUpdate.userErrors' "pageUpdate ${handle}"
    printf '%s\n' "$response" | jq -r '.data.pageUpdate.page.id'
  else
    log "Creating page: ${handle}"
    response="$(
      graphql "$PAGE_CREATE_MUTATION" \
        "$(jq -nc --argjson page "$page_input" '{page: $page}')"
    )"
    require_no_top_level_errors "$response" "pageCreate ${handle}"
    require_no_user_errors "$response" '.data.pageCreate.userErrors' "pageCreate ${handle}"
    printf '%s\n' "$response" | jq -r '.data.pageCreate.page.id'
  fi
}

public_preview_page_id="$(ensure_page "$PUBLIC_PREVIEW_PAGE_HANDLE" "$PUBLIC_PREVIEW_PAGE_TITLE" "$PUBLIC_PREVIEW_TEMPLATE_SUFFIX")"
preview_stage_page_id="$(ensure_page 'preview-stage' 'Preview Terms' 'preview-stage')"
research_notes_page_id="$(ensure_page 'research-notes' 'Research Notes' 'research-notes')"
faq_page_id="$(ensure_page 'faq' 'FAQ' 'faq')"

product_body_html="$(jq -r '.product.body_html' "$THEME_DIR/product-schema.json")"
log "Updating draft product"
product_response="$(
  graphql "$PRODUCT_UPDATE_MUTATION" \
    "$(
      jq -nc \
        --arg id "$product_id" \
        --arg title "$PRODUCT_TITLE" \
        --arg handle "$PRODUCT_HANDLE" \
        --arg productType "$PRODUCT_TYPE" \
        --arg templateSuffix "$PRODUCT_TEMPLATE_SUFFIX" \
        --arg descriptionHtml "$product_body_html" \
        '{
          product: {
            id: $id,
            title: $title,
            handle: $handle,
            productType: $productType,
            tags: ["copper", "pour-over", "preview-only"],
            status: "DRAFT",
            templateSuffix: $templateSuffix,
            descriptionHtml: $descriptionHtml
          }
        }'
    )"
)"
require_no_top_level_errors "$product_response" 'productUpdate'
require_no_user_errors "$product_response" '.data.productUpdate.userErrors' 'productUpdate'

log "Updating variant SKU and locked preview price"
variant_response="$(
  graphql "$VARIANT_UPDATE_MUTATION" \
    "$(
      jq -nc \
        --arg productId "$product_id" \
        --arg variantId "$variant_id" \
        --arg sku "$PRODUCT_SKU" \
        --arg price "$PRODUCT_PRICE" \
        '{
          productId: $productId,
          variants: [
            {
              id: $variantId,
              price: $price,
              taxable: true,
              inventoryPolicy: "DENY",
              inventoryItem: {
                sku: $sku,
                tracked: true,
                requiresShipping: true
              }
            }
          ]
        }'
    )"
)"
require_no_top_level_errors "$variant_response" 'productVariantsBulkUpdate'
require_no_user_errors "$variant_response" '.data.productVariantsBulkUpdate.userErrors' 'productVariantsBulkUpdate'

sample_verified_type="$(printf '%s\n' "$state" | jq -r '.data.productByHandle.metafields.nodes[]? | select(.namespace == "product_info" and .key == "sample_verified") | .type' | head -n1)"
if [[ -z "$sample_verified_type" || "$sample_verified_type" == "null" ]]; then
  sample_verified_type="boolean"
fi

if [[ "$sample_verified_type" != "boolean" ]]; then
  log "Metafield product_info.sample_verified already exists as ${sample_verified_type}; preserving type and value=false"
fi

log "Setting product preview metafields"
metafields_response="$(
  graphql "$METAFIELDS_SET_MUTATION" \
    "$(
      jq -nc \
        --arg ownerId "$product_id" \
        --arg materialNote "$MATERIAL_NOTE" \
        --arg sampleVerifiedType "$sample_verified_type" \
        '{
          metafields: [
            {
              ownerId: $ownerId,
              namespace: "product_info",
              key: "material_note",
              type: "single_line_text_field",
              value: $materialNote
            },
            {
              ownerId: $ownerId,
              namespace: "product_info",
              key: "single_sku_locked",
              type: "boolean",
              value: "true"
            },
            {
              ownerId: $ownerId,
              namespace: "product_info",
              key: "sample_verified",
              type: $sampleVerifiedType,
              value: "false"
            }
          ]
        }'
    )"
)"
require_no_top_level_errors "$metafields_response" 'metafieldsSet'
require_no_user_errors "$metafields_response" '.data.metafieldsSet.userErrors' 'metafieldsSet'

privacy_policy_body="$(cat <<'HTML'
<p>Email sign-up is used for updates on this product only.</p>
<p>This site is in product-preview mode. It does not offer checkout, preorder, waitlist, or any purchase commitment at this stage.</p>
<p>If updates are no longer needed, subscribers can opt out from the email footer.</p>
HTML
)"

log "Updating privacy policy"
policy_response="$(
  graphql "$SHOP_POLICY_UPDATE_MUTATION" \
    "$(
      jq -nc \
        --arg body "$privacy_policy_body" \
        '{
          shopPolicy: {
            type: "PRIVACY_POLICY",
            body: $body
          }
        }'
    )"
)"
if [[ "$(printf '%s\n' "$policy_response" | jq '(.errors // []) | length')" != "0" ]]; then
  required_access="$(printf '%s\n' "$policy_response" | jq -r '.errors[0].extensions.requiredAccess // empty')"
  if [[ "$required_access" == *"write_legal_policies"* ]]; then
    log "Skipping privacy policy update: current token is missing write_legal_policies scope"
  else
    require_no_top_level_errors "$policy_response" 'shopPolicyUpdate'
  fi
else
  require_no_user_errors "$policy_response" '.data.shopPolicyUpdate.userErrors' 'shopPolicyUpdate'
fi

menu_id_by_handle() {
  local handle="$1"
  printf '%s\n' "$state" | jq -r --arg handle "$handle" '.data.menus.nodes[]? | select(.handle == $handle) | .id' | head -n1
}

ensure_menu() {
  local handle="$1"
  local title="$2"
  local items_json="$3"
  local existing_id
  local response

  existing_id="$(menu_id_by_handle "$handle")"
  if [[ -n "$existing_id" ]]; then
    log "Updating menu: ${handle}"
    response="$(
      graphql "$MENU_UPDATE_MUTATION" \
        "$(jq -nc --arg id "$existing_id" --arg title "$title" --arg handle "$handle" --argjson items "$items_json" '{id: $id, title: $title, handle: $handle, items: $items}')"
    )"
    require_no_top_level_errors "$response" "menuUpdate ${handle}"
    require_no_user_errors "$response" '.data.menuUpdate.userErrors' "menuUpdate ${handle}"
    printf '%s\n' "$response" | jq -r '.data.menuUpdate.menu.id'
  else
    log "Creating menu: ${handle}"
    response="$(
      graphql "$MENU_CREATE_MUTATION" \
        "$(jq -nc --arg title "$title" --arg handle "$handle" --argjson items "$items_json" '{title: $title, handle: $handle, items: $items}')"
    )"
    require_no_top_level_errors "$response" "menuCreate ${handle}"
    require_no_user_errors "$response" '.data.menuCreate.userErrors' "menuCreate ${handle}"
    printf '%s\n' "$response" | jq -r '.data.menuCreate.menu.id'
  fi
}

main_menu_items="$(
  jq -nc \
    --arg publicPreviewPageId "$public_preview_page_id" \
    --arg faqPageId "$faq_page_id" \
    --arg notifyUrl "${STOREFRONT_BASE_URL}/#notify-cta" \
    '[
      {title: "Home", type: "FRONTPAGE"},
      {title: "Product Details", type: "PAGE", resourceId: $publicPreviewPageId},
      {title: "FAQ", type: "PAGE", resourceId: $faqPageId},
      {title: "Notify Me", type: "HTTP", url: $notifyUrl}
    ]'
)"

footer_menu_items="$(
  jq -nc \
    --arg previewPageId "$preview_stage_page_id" \
    --arg faqPageId "$faq_page_id" \
    --arg privacyUrl "${STOREFRONT_BASE_URL}/policies/privacy-policy" \
    '[
      {title: "Preview Terms", type: "PAGE", resourceId: $previewPageId},
      {title: "FAQ", type: "PAGE", resourceId: $faqPageId},
      {title: "Privacy Policy", type: "HTTP", url: $privacyUrl}
    ]'
)"

ensure_menu 'main-menu' 'Main menu' "$main_menu_items" >/dev/null
ensure_menu 'footer' 'Footer menu' "$footer_menu_items" >/dev/null

log "Re-querying state for verification"
final_state="$(graphql "$CURRENT_STATE_QUERY" "$state_variables")"
require_no_top_level_errors "$final_state" 'final state query'

printf '\n=== Shopify preview sync summary ===\n'
printf '%s\n' "$final_state" | jq '{
  shop: .data.shop,
  mainTheme: (.data.themes.nodes[] | select(.role == "MAIN") | {id, name, role}),
  product: (
    .data.productByHandle
    | {
      id,
      handle,
      title,
      status,
      templateSuffix,
      productType,
      tags,
      variant: (.variants.nodes[0] | {id, sku, price, inventoryQuantity, inventoryPolicy, inventoryItem}),
      metafields: (.metafields.nodes | map({namespace, key, type, value}))
    }
  ),
  pages: (
    .data.pages.nodes
    | map(select(.handle as $h | ["copper-kettle-preview", "preview-stage", "research-notes", "faq"] | index($h)))
    | map({id, handle, title, templateSuffix, isPublished})
  ),
  menus: (
    .data.menus.nodes
    | map(select(.handle as $h | ["main-menu", "footer"] | index($h)))
    | map({handle, title, items: (.items | map({title, type, url, resourceId}))})
  )
}'

printf '\n=== Storefront HTTP probe ===\n'
for path in \
  "/" \
  "/pages/${PUBLIC_PREVIEW_PAGE_HANDLE}" \
  "/pages/preview-stage" \
  "/pages/research-notes" \
  "/pages/faq" \
  "/products/${PRODUCT_HANDLE}"
do
  status="$(curl -sS -o /dev/null -w '%{http_code}' "${STOREFRONT_BASE_URL}${path}" || true)"
  if [[ "$path" == "/products/${PRODUCT_HANDLE}" && "$status" == "404" ]]; then
    printf '%s -> %s (expected while product remains DRAFT)\n' "$path" "$status"
  else
    printf '%s -> %s\n' "$path" "$status"
  fi
done

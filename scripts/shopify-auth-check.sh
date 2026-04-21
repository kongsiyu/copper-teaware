#!/usr/bin/env bash
# Verify Shopify Admin API authentication without printing reusable secrets.
#
# Supported inputs:
#   SHOPIFY_STORE_DOMAIN
#   SHOPIFY_CLIENT_ID / SHOPIFY_CLIENT_SECRET
#   Compatibility aliases: SHOPIFY_CLINET_ID / SHOPIFY_SECRET
#   Optional legacy fallback: SHOPIFY_ADMIN_API_TOKEN

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

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

if [[ -z "$SHOPIFY_ADMIN_API_TOKEN" ]]; then
  : "${SHOPIFY_CLIENT_ID:?需要设置 SHOPIFY_CLIENT_ID（或兼容别名 SHOPIFY_CLINET_ID）环境变量}"
  : "${SHOPIFY_CLIENT_SECRET:?需要设置 SHOPIFY_CLIENT_SECRET（或兼容别名 SHOPIFY_SECRET）环境变量}"
fi

request_token() {
  local response
  local body
  local status

  response="$(
    curl -sS -w '\n%{http_code}' \
      -X POST "https://${SHOPIFY_STORE_DOMAIN}/admin/oauth/access_token" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode 'grant_type=client_credentials' \
      --data-urlencode "client_id=${SHOPIFY_CLIENT_ID}" \
      --data-urlencode "client_secret=${SHOPIFY_CLIENT_SECRET}"
  )"

  status="$(printf '%s\n' "$response" | tail -n1)"
  body="$(printf '%s\n' "$response" | sed '$d')"

  if [[ "$status" != "200" ]]; then
    echo "Token exchange failed: HTTP ${status}" >&2
    if printf '%s' "$body" | jq -e . >/dev/null 2>&1; then
      printf '%s\n' "$body" | jq -r '.error_description // .error // .errors // .message // tostring' >&2
    else
      printf '%s\n' "$body" \
        | tr '\n' ' ' \
        | sed -E 's/<[^>]+>/ /g; s/&quot;/"/g; s/&amp;/\&/g; s/[[:space:]]+/ /g' \
        | grep -oE 'Oauth error [^<]+' \
        | head -n1 >&2 || true
    fi
    return 1
  fi

  printf '%s\n' "$body"
}

graphql_check() {
  local token="$1"
  local response
  local body
  local status

  response="$(
    curl -sS -w '\n%{http_code}' \
      -X POST "https://${SHOPIFY_STORE_DOMAIN}/admin/api/2025-01/graphql.json" \
      -H 'Content-Type: application/json' \
      -H "X-Shopify-Access-Token: ${token}" \
      --data '{"query":"query AuthCheck { shop { name myshopifyDomain } products(first: 1) { edges { node { id handle } } } }"}'
  )"

  status="$(printf '%s\n' "$response" | tail -n1)"
  body="$(printf '%s\n' "$response" | sed '$d')"

  if [[ "$status" != "200" ]]; then
    echo "GraphQL check failed: HTTP ${status}" >&2
    printf '%s\n' "$body" | jq -r '.errors // .message // tostring' >&2
    return 1
  fi

  if [[ "$(printf '%s\n' "$body" | jq -r '(.errors // []) | length')" != "0" ]]; then
    echo "GraphQL returned errors:" >&2
    printf '%s\n' "$body" | jq -r '.errors' >&2
    return 1
  fi

  printf '%s\n' "$body"
}

echo "=== Shopify Admin API auth check ==="
echo "Store: ${SHOPIFY_STORE_DOMAIN}"

if [[ -n "$SHOPIFY_ADMIN_API_TOKEN" ]]; then
  auth_mode="legacy_token"
  access_token="$SHOPIFY_ADMIN_API_TOKEN"
  echo "Auth mode: legacy access token"
else
  auth_mode="client_credentials"
  echo "Auth mode: client credentials grant"
  token_response="$(request_token)"
  access_token="$(printf '%s\n' "$token_response" | jq -r '.access_token')"
  token_scope="$(printf '%s\n' "$token_response" | jq -r '.scope')"
  token_expires_in="$(printf '%s\n' "$token_response" | jq -r '.expires_in')"
  echo "Token exchange: ok"
  echo "Granted scope: ${token_scope}"
  echo "Expires in: ${token_expires_in}s"
fi

graphql_response="$(graphql_check "$access_token")"
shop_name="$(printf '%s\n' "$graphql_response" | jq -r '.data.shop.name')"
shop_domain="$(printf '%s\n' "$graphql_response" | jq -r '.data.shop.myshopifyDomain')"
product_count="$(printf '%s\n' "$graphql_response" | jq -r '.data.products.edges | length')"

echo "GraphQL check: ok"
echo "Shop name: ${shop_name}"
echo "Shop domain: ${shop_domain}"
echo "Visible products in sample query: ${product_count}"
echo "Auth verification completed via ${auth_mode}."

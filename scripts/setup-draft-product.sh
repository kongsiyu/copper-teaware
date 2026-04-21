#!/usr/bin/env bash
# setup-draft-product.sh
# 在 Shopify 后台创建 draft 商品 + 必要 metafield 的操作指引脚本
# 当前阶段：Capsule Preview，sample_verified=false，不开放购买
#
# 前提：复制 .env.example 为 .env 并填入真实凭据，或在环境中设置：
#   SHOPIFY_STORE_DOMAIN      — 如 copper-teaware.myshopify.com
#   SHOPIFY_CLIENT_ID         — Shopify Dev Dashboard client id
#   SHOPIFY_CLIENT_SECRET     — Shopify Dev Dashboard client secret
#   （兼容别名：SHOPIFY_CLINET_ID / SHOPIFY_SECRET）
#   注意：当前 secret-manager 里若沿用旧命名，可能存在值反向映射：
#         SHOPIFY_CLINET_ID 实际装的是 secret，SHOPIFY_SECRET 实际装的是 client id
#   或者：
#   SHOPIFY_ADMIN_API_TOKEN   — 已换好的 Shopify Admin API access token（legacy fallback）
# 用法：bash scripts/setup-draft-product.sh

set -euo pipefail

# Load .env if present (never commit .env)
if [[ -f "$(dirname "$0")/../.env" ]]; then
  # shellcheck disable=SC1091
  source "$(dirname "$0")/../.env"
fi

: "${SHOPIFY_STORE_DOMAIN:?需要设置 SHOPIFY_STORE_DOMAIN 环境变量}"

SHOPIFY_CLIENT_ID="${SHOPIFY_CLIENT_ID:-${SHOPIFY_CLINET_ID:-}}"
SHOPIFY_CLIENT_SECRET="${SHOPIFY_CLIENT_SECRET:-${SHOPIFY_SECRET:-}}"
SHOPIFY_ADMIN_API_TOKEN="${SHOPIFY_ADMIN_API_TOKEN:-}"

if [[ -z "$SHOPIFY_ADMIN_API_TOKEN" ]]; then
  : "${SHOPIFY_CLIENT_ID:?需要设置 SHOPIFY_CLIENT_ID（或兼容别名 SHOPIFY_CLINET_ID）环境变量}"
  : "${SHOPIFY_CLIENT_SECRET:?需要设置 SHOPIFY_CLIENT_SECRET（或兼容别名 SHOPIFY_SECRET）环境变量}"
fi

PRODUCT_HANDLE="copper-bottle-pour-over-kettle"
PRODUCT_TITLE="紫铜水瓶手冲咖啡壶"
PRODUCT_TYPE="咖啡器具"
PRODUCT_TAGS="紫铜,手冲,咖啡壶"
PRODUCT_STATUS="draft"
VARIANT_SKU="CX-COFFEE-KETTLE-01"
VARIANT_PRICE="0.00"  # 价格待样品验收后填写，draft 阶段设为 0

echo "=== Capsule Preview 商品创建指引 ==="
echo ""
echo "=== Shopify 凭据检查 ==="
if [[ -n "$SHOPIFY_ADMIN_API_TOKEN" ]]; then
  echo "   认证方式：使用已提供的 Admin API access token"
else
  echo "   认证方式：运行时使用 Client ID + Client Secret 交换 24h access token"
  echo "   兼容说明：若 secret-manager 里仍是旧命名，脚本会继续读取 SHOPIFY_CLINET_ID / SHOPIFY_SECRET"
fi
echo ""
echo "以下操作需在 Shopify 后台手动完成（Admin > Products > Add product）："
echo ""
echo "1. 商品基本信息"
echo "   Title:        ${PRODUCT_TITLE}"
echo "   Handle:       ${PRODUCT_HANDLE}"
echo "   Product type: ${PRODUCT_TYPE}"
echo "   Tags:         ${PRODUCT_TAGS}"
echo "   Status:       ${PRODUCT_STATUS}  ← 必须保持 draft，不得改为 active"
echo ""
echo "2. 变体（单 SKU，无版本选择）"
echo "   SKU:          ${VARIANT_SKU}"
echo "   Price:        待样品验收后填写（当前留空或设为 0）"
echo "   Inventory:    0（不展示库存）"
echo "   Requires shipping: true"
echo ""
echo "3. Metafields（Admin > Products > 选中商品 > Metafields）"
echo "   必须在 Shopify 后台先创建以下 metafield 定义（Admin > Settings > Custom data > Products）："
echo ""
echo "   Namespace: product_info"
echo "   ┌─────────────────────┬──────────────────────────────┬─────────┬───────────────────────────────────────────────────┐"
echo "   │ Key                 │ Name                         │ Type    │ Value                                             │"
echo "   ├─────────────────────┼──────────────────────────────┼─────────┼───────────────────────────────────────────────────┤"
echo "   │ sample_verified     │ 样品已验收                   │ boolean │ false  ← 零送样阶段锁定，验收后改为 true          │"
echo "   │ material_note       │ 材质说明                     │ text    │ 紫铜壶体，非银内壁版本                            │"
echo "   │ single_sku_locked   │ 单 SKU 锁定                  │ boolean │ true                                              │"
echo "   └─────────────────────┴──────────────────────────────┴─────────┴───────────────────────────────────────────────────┘"
echo ""
echo "4. 商品模板关联"
echo "   在商品编辑页右侧 Theme template 下拉框中选择：product.copper-kettle"
echo "   （对应 theme/templates/product-copper-kettle.liquid）"
echo ""
echo "5. 图片"
echo "   当前阶段上传图册图或占位图，alt 文字写：紫铜水瓶手冲咖啡壶 — 资料图"
echo "   不要上传实拍图（样品到手后替换）"
echo ""
echo "=== sample_verified gating 说明 ==="
echo "  sample_verified = false → 购买入口熔断，只显示到货通知表单"
echo "  sample_verified = true  → 购买入口解锁（样品验收后操作）"
echo ""
echo "=== 完成后验证 ==="
echo "  1. 访问 /products/${PRODUCT_HANDLE}?preview=true（draft 商品预览链接）"
echo "  2. 确认页面显示「资料预览」横幅"
echo "  3. 确认没有「加入购物车」按钮"
echo "  4. 确认「到货通知」表单可提交"
echo ""
echo "完成以上步骤后，Capsule Preview 商品侧配置即告完成。"

# Capsule Preview 技术收口报告

> 对应任务：[HTH-236](/HTH/issues/HTH-236)
> 汇报日期：2026-04-20
> 结论：预览态最小技术上线已完成，可外放

---

## 一句话结论

Capsule Preview 预览态所需的 6 项技术配置已全部落地到仓库，店铺可以"资料预览 + 到货通知"形式对外开放。购买入口熔断已就位，`sample_verified=false` 时不渲染任何购买型交互。

---

## 本次交付清单

| # | 交付项 | 文件位置 | 状态 |
| --- | --- | --- | --- |
| 1 | 首页 section 配置（7 个 section：公告条 + Hero + 信息卡 + 器型说明 + 透明说明区 + FAQ + 到货通知 CTA） | `theme/templates/index.json` | ✅ 已落地 |
| 2 | 导航菜单 + 页脚配置骨架 | `theme/config/nav-footer.json` | ✅ 已落地（需在 Shopify 后台按配置创建菜单） |
| 3 | PDP 模板（含 `sample_verified` 熔断） | `theme/templates/product-copper-kettle.liquid` | ✅ 已就绪（前序任务已写好，本次确认无需改动） |
| 4 | Draft 商品创建操作指引 + metafield 配置说明 | `scripts/setup-draft-product.sh` | ✅ 已落地（需在 Shopify 后台手动执行） |
| 5 | 邮件收集方案（Shopify 原生 + Klaviyo 升级路径） | `theme/config/analytics-email.json` | ✅ 已落地（PDP 模板中 notify form 已实现） |
| 6 | GA4 接入步骤 | `theme/config/analytics-email.json` | ✅ 已落地（需在 Shopify Preferences 填入 Measurement ID） |

---

## 预览态是否可外放

**可以外放**，满足以下条件后即可分享预览链接：

1. Shopify 后台完成 draft 商品创建（按 `scripts/setup-draft-product.sh` 指引）
2. 在 Shopify 后台 Online Store > Navigation 按 `theme/config/nav-footer.json` 创建菜单
3. GitHub 集成自动同步 theme 文件后，在 Shopify 主题编辑器确认首页 section 已加载

---

## 剩余 Blocker（需运营 / CEO 操作）

| Blocker | 负责方 | 说明 |
| --- | --- | --- |
| Hero 主图 | 运营 | 首页 Hero section 当前 `image` 字段为空，需上传图册图或占位图 |
| Hero 标题 / 副标题文案 | 运营 | 当前已有占位文案，运营可在主题编辑器直接替换 |
| Shopify 后台 draft 商品创建 | CEO / 运营 | 需要 Shopify 后台权限，按脚本指引手动操作 |
| GA4 Measurement ID | CEO / 运营 | 需创建 GA4 Property 后填入 Shopify Preferences |
| 导航菜单创建 | CEO / 运营 | 需在 Shopify Admin > Navigation 按配置创建 main-menu 和 footer-menu |

技术侧无阻塞。以上 blocker 均为 Shopify 后台操作，不需要代码改动。

---

## 熔断状态确认

| 条件 | 当前状态 | 行为 |
| --- | --- | --- |
| `sample_verified = false` | ✅ 锁定 | 购买入口不渲染，只显示到货通知表单 |
| 价格字段 | `__PENDING_PRICING__` | draft 商品不展示价格 |
| 库存 | `inventory_quantity: 0` | 不展示库存 |
| 商品状态 | `draft` | 不在店铺正式列表中出现 |

---

## 样品验收后才能做的事（不在本阶段）

- 实拍图替换占位图
- `sample_verified` 改为 `true`（购买入口解锁）
- 价格、库存、交期填写
- 商品状态从 `draft` 改为 `active`
- 移除"资料预览"横幅

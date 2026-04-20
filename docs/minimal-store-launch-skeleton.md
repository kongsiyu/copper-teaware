# 最小店铺上线骨架 — 铜器茶具咖具店

> 范围界定文档，不是实现计划。
> 依据：HTH-230 任务要求 + 现有 theme/ 骨架现状审查。
> 当前阶段：零送样，单 SKU 锁定（紫铜水瓶手冲咖啡壶）。

---

## 一、当前已有 vs 缺失

### 已有

| 文件 | 状态 |
| --- | --- |
| `theme/templates/product-copper-kettle.liquid` | 完整 PDP 模板，含 sample_verified 门控逻辑 |
| `theme/product-schema.json` | 单 SKU 商品结构，含 metafield 定义 |
| `docs/pre-launch-gating-checklist.md` | 三阶段上线检查清单 |
| `docs/coffee-kettle-zero-sample-ia-content-pack.md` | 页面 IA 和内容边界定义 |

### 缺失（空店铺到"可上线预览"之间的 gap）

| 模块 | 缺失内容 |
| --- | --- |
| 主题基础 | 没有选定 Shopify 主题；sections/、config/、locales/ 目录为空 |
| 首页 | 无首页模板（`templates/index.liquid` 或 `index.json`） |
| 导航 / 页头页脚 | 无 header/footer section，无菜单配置 |
| 落地页 | 无独立落地页模板（可选，但 IA 文档已定义结构） |
| 主题配置 | 无 `config/settings_schema.json` 和 `config/settings_data.json` |
| 本地化 | 无 `locales/zh-CN.json`（中文店铺必须） |
| 商品创建 | product-schema.json 存在但 Shopify Draft 商品尚未创建 |
| 结账配置 | 支付方式、运费、税务未配置（上线前必须） |

---

## 二、模块优先级判断

### 必须现在做（零送样预览上线的最小集）

| 模块 | 理由 |
| --- | --- |
| **选定主题** | 所有 section/template 都依赖主题基础；不选主题，其他都是空文件 |
| **首页模板** | 店铺入口；IA 文档已定义 8 个 section 顺序，需要落地 |
| **PDP 推送到 Shopify** | `product-copper-kettle.liquid` 已写好，需要推送到 theme 并在 Shopify 后台关联 |
| **Shopify Draft 商品创建** | product-schema.json 已有结构，需要在 Shopify 后台或 API 创建 draft 商品 |
| **metafield `sample_verified=false`** | PDP 门控逻辑依赖此字段；不设置则 CTA 逻辑失效 |
| **到货通知表单** | 唯一 CTA；需要 Shopify Customer form 或第三方邮件收集（Klaviyo/Mailchimp）接通 |

### 可后置（预览上线后再补）

| 模块 | 理由 |
| --- | --- |
| 落地页独立模板 | 首页 + PDP 已能承接流量；落地页是优化项 |
| 本地化文件 | 中文内容可先硬编码在模板里；locales 是维护性优化 |
| SEO meta / sitemap | 零送样阶段不需要搜索引擎收录 |
| 博客 / 内容页 | 当前阶段无内容运营需求 |
| 多货币 / 多语言 | 单市场先跑 |

### 当前不做

| 模块 | 理由 |
| --- | --- |
| 购物车 / 结账流程 | 零送样阶段无购买入口，结账配置等样品验收后再做 |
| 库存管理 / 物流配置 | 同上 |
| 评论系统 | 无成交，无评论 |
| 多 SKU / 变体选择器 | HTH-220 单 SKU 锁定，禁止引入 |
| 促销 / 折扣 / 礼品卡 | 当前阶段无交易 |

---

## 三、主题选择策略

**建议：先用现成主题轻改，不定制。**

理由：
- 当前只有 1 个 SKU，页面结构简单（Hero + 规格 + FAQ + 通知表单）
- 零送样阶段不需要复杂的购物体验
- 定制主题需要前端开发资源，与当前"范围界定"阶段不匹配

**最小可行建议：**
1. 选 Shopify 免费主题 **Dawn**（官方默认，结构干净，Liquid 2.0 兼容）
2. 在 Dawn 基础上覆盖 `templates/product-copper-kettle.liquid`（已写好）
3. 首页用 Dawn 的 section 拼装，不写自定义 section
4. 颜色/字体在 `config/settings_data.json` 里调整（铜器调性：深棕 `#4d3727`、米白 `#f7f3ee`）

Dawn 的限制：默认英文，中文字体需要在主题设置里手动指定（如 Noto Sans SC）。这是可接受的轻改范围。

---

## 四、必要 App / 配置类别（最多 3 个）

| 类别 | 具体工具 | 为什么必要 |
| --- | --- | --- |
| **邮件收集** | Klaviyo 或 Mailchimp（免费层） | 到货通知是唯一 CTA；Shopify 原生 Customer form 可用但通知自动化弱，需要邮件工具接收和发送到货通知 |
| **分析** | Google Analytics 4（免费） | 需要知道有没有人访问、通知表单转化率；零送样阶段的唯一量化指标 |
| **（可选）密码保护** | Shopify 内置 Password page | 如果不想让搜索引擎收录或不想公开访问，可以开启密码保护，只给内部和私域用户访问链接 |

不需要的 app：评论、订阅、会员、多货币、运费计算器、聊天客服——这些都是样品验收后的事。

---

## 五、CEO 可直接复述的中文结论

> 当前店铺已有商品信息结构和商品详情页模板，但还缺三件事才能上线预览：
> 第一，选一个 Shopify 主题（建议用免费的 Dawn，不需要定制）；
> 第二，把已有的商品模板推送到主题，并在 Shopify 后台创建这个商品的草稿；
> 第三，接通一个邮件收集工具（Klaviyo 或 Mailchimp 免费版），让"到货通知"表单能真正收到邮箱。
>
> 这三步完成后，店铺就能以"资料预览 + 到货通知"的形式对外开放，不需要价格、库存或购买流程。
> 购物车、结账、多 SKU、评论这些功能，等样品到手验收后再做，现在不碰。

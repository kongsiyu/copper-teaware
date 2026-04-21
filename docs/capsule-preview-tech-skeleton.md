# Capsule Preview 技术骨架与预览态 gating 收口

> 对应任务：[HTH-232](/HTH/issues/HTH-232)
> 当前阶段：零送样 → Capsule Preview 可外放
> 结论日期：2026-04-21
> 依据：[HTH-139](/HTH/issues/HTH-139) 方向确认 + [HTH-230](/HTH/issues/HTH-230) 骨架范围 + 当前仓库实际状态

---

## 一、主题与开发流基线确认

**当前基线：Wokiee Artisan Workshop（已导入，可预览）**

前序文档（[HTH-230](/HTH/issues/HTH-230) 的 `minimal-store-launch-skeleton.md`）曾建议使用 Dawn 主题，但那是分析阶段的备选建议。当前实际落地基线是 **Wokiee Artisan Workshop**，已通过 Shopify GitHub 集成导入并可预览。

后续所有主题调整、section 配置和模板推送，均以 **Wokiee Artisan Workshop** 为唯一基线，不再讨论 Dawn 切换。团队口径统一：Dawn 建议已作废，以当前已落地主题为准。

**开发流**：主仓库 `copper-teaware` + `theme/` submodule（`copper-teaware-theme`）→ Shopify GitHub 集成自动同步。
- 主题文件改动提交到 `theme/` submodule
- 主仓库更新 submodule 指针
- Shopify 通过 GitHub 集成拉取最新 theme

---

## 二、预览态最小页面/模块清单

### 页面清单

| 页面 | 状态 | 说明 |
| --- | --- | --- |
| 首页（Homepage） | **已具备骨架，待推送 / 配图** | `theme/templates/index.json` 已写好，包含 8 个 section；剩余是 Hero 素材和主题编辑器配置 |
| 商品详情页 PDP | **已具备骨架，待推送** | `theme/templates/product-copper-kettle.liquid` 已写好，需推送到 Wokiee 并在 Shopify 后台关联 |
| 研究 / 阶段说明 / FAQ 页面 | **已具备模板，待后台创建页面** | `page.preview-stage`、`page.research-notes`、`page.faq` 已写好；需在 Shopify Pages 里创建对应 handle 并绑定模板 |
| 导航 / 页头 / 页脚 | **已具备骨架，待后台执行** | `theme/config/nav-footer.json` 已给出菜单结构；需在 Wokiee 主题编辑器和 Navigation 中配置 |
| 落地页（Landing page） | **可后置** | 首页 + PDP 已能承接流量；落地页是优化项，Capsule Preview 阶段不阻塞 |
| 关于页（About） | **可后置** | 零送样阶段无品牌故事需求 |

### 模块清单（首页 8 sections）

依据 `docs/coffee-kettle-zero-sample-ia-content-pack.md` 定义的首页 section 顺序：

| 顺序 | Section | 状态 | 备注 |
| --- | --- | --- | --- |
| 1 | 阶段说明条（Announcement bar） | **已具备**（Wokiee 内置） | 配置文案即可 |
| 2 | 单品预告 Hero | **本阶段必须配置** | 图册主图或占位图 + 到货通知按钮 |
| 3 | 已知信息卡（Feature cards） | **本阶段必须配置** | 3-4 张参数卡，标待复核 |
| 4 | 器型说明（Image + text） | **本阶段必须配置** | 图册裁切图 + 文案 |
| 5 | 研究记录预告（Image + text） | **已具备** | 链到 `/pages/research-notes`，承接为什么只开放通知和待复核边界 |
| 6 | 透明说明区（Rich text） | **本阶段必须配置** | 已知/待复核两列清单 |
| 7 | FAQ 摘要（Collapsible content） | **本阶段必须配置** | 8 条核心问答已写入模板 |
| 8 | 到货通知 CTA（Email signup） | **本阶段必须配置** | 接 Klaviyo 或 Shopify 原生表单 |

### PDP 模块清单

| 模块 | 状态 | 备注 |
| --- | --- | --- |
| 状态横幅（样品待验收提示） | **已具备**（template 已写） | `sample_verified=false` 时自动显示 |
| 媒体区（图册占位图） | **本阶段必须配置** | 需上传图册图或占位图到 Shopify |
| 标题 + 材质标签 | **已具备** | template 已写 |
| 单 SKU 锁定说明 | **已具备** | template 已写，无变体选择器 |
| 到货通知区（替代购买按钮） | **已具备**（template 已写） | `sample_verified=false` 时显示通知表单 |
| 规格表（待复核标注） | **已具备** | template 已写 |
| FAQ | **已具备** | template 已写 |
| 购买入口（Add to cart） | **已熔断** | `sample_verified=false` 时不渲染 |

### 独立内容页模板

| 模板 | 路由 | 状态 | 备注 |
| --- | --- | --- | --- |
| `page.preview-stage` | `/pages/preview-stage` | **已具备** | 阶段边界、解锁条件和 notify-only 说明 |
| `page.research-notes` | `/pages/research-notes` | **已具备** | 研究记录、规格底稿和禁写红线 |
| `page.faq` | `/pages/faq` | **已具备** | 阶段 FAQ、产品 FAQ 和通知 / 隐私 FAQ |

以上 3 个模板均已写入 `theme/`。在 Shopify 后台创建页面时，若希望直接使用仓库默认正文，页面正文保持空白即可。

---

## 三、notify-only 技术 gating

### sample_verified 熔断逻辑

当前 `theme/templates/product-copper-kettle.liquid` 已实现：

```
Capsule Preview 当前模板 → 强制隐藏购买入口，显示到货通知表单
sample_verified=true 不会在当前模板内直接解锁购买入口
```

**metafield 配置**（必须在 Shopify 后台设置）：
- Namespace: `product_info`
- Key: `sample_verified`
- Type: `boolean`
- 当前值: `false`（零送样阶段锁定）

**价格/库存/交期熔断**：
- `price` 字段在 `product-schema.json` 中保持 `0.00`，前台模板不渲染价格
- `inventory_quantity: 0`，不展示库存
- 交期字段不存在于当前 schema，不渲染

### 邮件收集最小接入方案

| 方案 | 接入复杂度 | 限制条件 |
| --- | --- | --- |
| **Shopify 原生 Customer form**（推荐先用） | 低，无需 App | 通知自动化弱；需手动导出邮箱列表；适合 Capsule Preview 阶段 |
| **Klaviyo 免费层**（推荐后续升级） | 中，需安装 App + 配置 List | 免费层 500 联系人；自动化通知强；需 Shopify App 权限 |
| **Mailchimp** | 中 | 与 Shopify 集成需第三方连接器；不如 Klaviyo 原生 |

**Capsule Preview 阶段建议**：先用 Shopify 原生 Customer form 收集邮箱，同步安装 Klaviyo 并配置 List，等到货通知量达到 20+ 再切换自动化流程。

**阻塞条件**：
- Klaviyo App 安装需要 Shopify 店铺已激活（非 trial 限制，但需要有效支付方式绑定）
- 如果店铺仍在 trial 期，Shopify 原生表单可用，Klaviyo 安装不受阻

### GA4 基础分析接入

| 步骤 | 操作 | 阻塞条件 |
| --- | --- | --- |
| 1 | 创建 GA4 Property | 无阻塞，免费 |
| 2 | 在 Shopify 后台 → Online Store → Preferences → Google Analytics 填入 Measurement ID | 需要 Shopify 店铺已激活或处于 trial 可配置状态 |
| 3 | 验证 pageview 事件 | 需要店铺可访问（密码保护模式下 GA4 仍可追踪） |

**最小追踪目标**：pageview + 到货通知表单提交（conversion event）。

---

## 四、与商业线对接接口

### 运营负责人最小内容接入清单

以下内容块需要运营提供，技术侧负责挂载到当前 Wokiee 主题：

| 内容块 | 运营需提供 | 技术挂载方式 | 优先级 |
| --- | --- | --- | --- |
| Hero 主图 | 图册主图（JPG/PNG，建议 1600×900px 以上）或占位图 | 上传到 Shopify Files，在主题编辑器 Hero section 配置 | 必须，阻塞首页上线 |
| Hero 标题 + 副标题 | 中文文案（参考 IA 文档已有草稿） | 主题编辑器 Hero section 文本字段 | 必须 |
| 到货通知表单文案 | 表单标题、说明文字、按钮文案、提交后确认文案 | 主题编辑器 Email signup section 或 Klaviyo 表单配置 | 必须 |
| FAQ 内容 | 4-5 条问答（参考 IA 文档已有草稿，运营确认即可） | 主题编辑器 Collapsible content section | 必须 |
| 透明说明区文案 | 已知信息 vs 待复核信息的对照清单（IA 文档已有草稿） | 主题编辑器 Rich text section | 必须 |
| 规格表数据 | 确认图册规格数值（500cc、口径 5cm 等）是否可对外展示 | PDP template 已写，运营确认后去掉待复核标注 | 可后置 |
| 器型说明图 | 图册裁切图或器型轮廓图（可用图册原图裁切） | 主题编辑器 Image + text section | 可后置 |

**并行原则**：技术侧可先用占位文案和占位图完成主题配置和 section 搭建，运营提供真实内容后直接在主题编辑器替换，不需要等待完整稿再开始技术工作。

### 技术侧挂载方式说明

Wokiee Artisan Workshop 主题支持通过 Shopify 主题编辑器（Customize）直接配置 section 内容，无需修改 Liquid 代码。运营负责人可以：
1. 在主题编辑器中直接编辑文案和上传图片
2. 不需要接触代码或 GitHub
3. 技术侧只需要确保 section 结构已搭好、PDP template 已推送

---

## 五、当前状态总结（预览态 gating 收口）

### 已具备

| 项目 | 状态 |
| --- | --- |
| 主题基线（Wokiee Artisan Workshop） | 已导入，可预览 |
| Shopify GitHub 集成 | 已接通 |
| 首页模板（8 sections） | 已写好，待推送 / 配图 |
| PDP 模板（含 sample_verified 熔断） | 已写好，需推送到 Wokiee |
| 独立页面模板（阶段说明 / research / FAQ） | 已写好，待在 Shopify 后台创建页面并绑定 |
| 导航配置骨架 | 已写好，见 `theme/config/nav-footer.json` |
| 商品 schema（单 SKU，非银内壁） | 已写好，需创建 Shopify draft 商品 |
| 字段拦截规则（cross-review 清单） | 已完成（[HTH-227](/HTH/issues/HTH-227)） |
| 零送样 gating 逻辑文档 | 已完成（[HTH-224](/HTH/issues/HTH-224)） |
| Theme 静态校验 | 已完成，`shopify theme check --path theme` 结果为 `9 files inspected with no offenses found` |

### 本阶段必须补齐（Capsule Preview 上线前 gating）

| 项目 | 负责方 | 阻塞条件 |
| --- | --- | --- |
| 首页 section 配置（Hero + 通知 CTA + FAQ + 说明区） | 技术 + 运营 | 运营提供 Hero 图和文案 |
| Shopify 页面创建 + 模板绑定（`preview-stage` / `research-notes` / `faq`） | 技术 / 运营 | 无阻塞 |
| 导航菜单 + 页脚配置 | 技术 | 无阻塞 |
| PDP template 推送到 Wokiee | 技术 | 无阻塞 |
| Shopify draft 商品创建 + metafield `sample_verified=false` | 技术 | 无阻塞 |
| 邮件收集接通（Shopify 原生或 Klaviyo） | 技术 | Shopify 店铺需可访问 |
| GA4 Measurement ID 配置 | 技术 | 需 GA4 Property 已创建 |

### 可后置（Capsule Preview 上线后再补）

| 项目 | 理由 |
| --- | --- |
| 落地页独立模板 | 首页 + PDP 已能承接流量 |
| 本地化文件（locales/zh-CN.json） | 中文内容可先在主题编辑器硬配置 |
| SEO meta / sitemap | 零送样阶段不需要搜索引擎收录 |
| Klaviyo 自动化通知流程 | 先用原生表单，量起来后再切 |
| 使用场景图（Multicolumn section） | 有图再配，无图跳过 |

### 样品验收后另开变更（不在本阶段）

- 实拍图替换占位图
- CEO / board 明确批准从 preview-only 切换到正式销售
- 新开工程变更移除当前 preview-only 模板熔断
- 价格、库存、交期填写
- 商品状态从 `draft` 改为 `active`
- 移除资料预览横幅

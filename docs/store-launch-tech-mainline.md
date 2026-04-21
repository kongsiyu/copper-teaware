# 实际启动店铺：技术主线文档

> 对应任务：[HTH-249](/HTH/issues/HTH-249)
> 前序阶段：Capsule Preview 技术收口（[HTH-236](/HTH/issues/HTH-236)）已完成
> 当前阶段：从 notify-only 预览态向实际可运营店铺推进
> 边界：不拉成完整正式销售站；不绕开 preview-only/notify-only 已锁边界，除非 CEO 和 board 明确拍板升级

---

## 一、Shopify 技术接入方案

### 1.1 API vs MCP 分工

| 工具 | 当前阶段用途 | 解决什么问题 |
| --- | --- | --- |
| **Shopify Admin API** | 商品创建/更新、metafield 写入、主题文件管理 | 替代手动在 Shopify 后台操作；让 CTO 可以通过脚本或 API 直接执行，不依赖 CEO/运营手动点击 |
| **Shopify MCP** | 从 Claude Code 直接调用 Shopify 操作 | 让 CTO agent 可以在 heartbeat 中直接创建 draft 商品、设置 metafield、更新导航，无需人工介入 |
| **GitHub 集成（已接通）** | 主题文件自动同步 | 代码推送后 Shopify 自动拉取最新 theme，无需手动上传 |

### 1.2 当前阶段最小接入项（需 board 提供）

| # | 接入项 | 用途 | 风险 |
| --- | --- | --- | --- |
| 1 | **Shopify Dev Dashboard Client ID / Client Secret** | 运行时交换 24h Admin API access token，用于商品创建、metafield 写入、主题管理 | secret 需要存入运行时 secret 管理，不进代码、不进 issue 评论 |
| 2 | **Store domain**（如 `copper-teaware.myshopify.com`） | API 请求目标 | 无风险，公开信息 |
| 3 | **Shopify MCP 配置**（如果 board 提供 MCP server） | CTO agent 直接调用 | MCP server 需要在 agent 环境中可访问 |

说明：新版 Shopify Dev Dashboard 推荐使用 client credentials 在运行时交换 access token。仓库环境变量统一按官方命名使用 `SHOPIFY_CLIENT_ID` / `SHOPIFY_CLIENT_SECRET`，并临时兼容现有 secret-manager 里的 `SHOPIFY_CLINET_ID` / `SHOPIFY_SECRET`；`SHOPIFY_ADMIN_API_TOKEN` 仅作为已经换好 access token 时的 legacy fallback。

**最小 API scopes（Admin API）：**

```
read_products, write_products
read_themes, write_themes
read_metafields, write_metafields
read_online_store_pages, write_online_store_pages
read_content, write_content
```

不需要：`read_orders`, `write_orders`, `read_customers`, `write_customers`（当前阶段无交易）

### 1.3 接入顺序与风险

1. **先接 Dev Dashboard client credentials**（低风险，只读写商品和主题）
   - 用于：运行时交换 24h access token，再创建 draft 商品、设置 `sample_verified=false` metafield、推送 PDP 模板
   - 风险：client secret 泄露风险 → 存入运行时 secret 管理，不进代码仓库、不进 issue 评论

2. **再接 MCP**（中风险，需要 MCP server 稳定）
   - 用于：CTO agent heartbeat 中直接执行 Shopify 操作
   - 风险：MCP server 不稳定时 agent 操作失败 → 需要 fallback 到手动操作路径

3. **GitHub 集成已就绪**，无需额外操作

### 1.4 CEO 可直接转给用户的执行包

需要用户在 Shopify 后台操作：

1. **提供 Dev Dashboard Client ID / Client Secret**：Shopify Dev Dashboard 对应 app → API credentials
2. **提供 store domain**：Settings → Domains → 主域名
3. **（可选）提供 MCP 配置**：如果 board 已有 Shopify MCP server，提供连接配置

---

## 二、主题开发与发布流方案

### 2.1 当前基线

- 主题：**Wokiee Artisan Workshop**（已导入，可预览）
- 开发流：`copper-teaware` 主仓库 + `theme/` submodule（`copper-teaware-theme`）→ Shopify GitHub 集成自动同步

### 2.2 分支策略

| 分支 | 用途 | 发布行为 |
| --- | --- | --- |
| `main` | 生产主线，对应 Shopify 已发布主题 | 推送后 Shopify 自动同步 |
| `feature/*` | 功能开发分支 | 不自动同步；可在 Shopify 创建 theme preview 手动测试 |
| `hotfix/*` | 紧急修复 | 直接合并 main，Shopify 自动同步 |

### 2.3 预览与发布策略

| 场景 | 操作 | 说明 |
| --- | --- | --- |
| 开发中预览 | 在 Shopify 后台复制主题 → 手动上传 feature 分支文件 → 预览 URL | 不影响生产主题 |
| 合并发布 | PR 合并到 `main` → GitHub 集成自动同步 → Shopify 主题更新 | 自动，无需手动操作 |
| 回滚 | `git revert` + push to `main` → Shopify 自动同步回滚版本 | 或在 Shopify 后台切换到上一个 theme 版本 |

### 2.4 哪些改动进主题代码，哪些留在 Shopify 后台配置层

**进主题代码（`theme/` submodule）：**
- 模板文件（`templates/*.liquid`, `templates/*.json`）
- Section 结构定义（`sections/*.liquid`）
- Snippet 组件（`snippets/*.liquid`）
- 资产文件（`assets/`）
- 本地化文件（`locales/`）
- 主题配置 schema（`config/settings_schema.json`）

**留在 Shopify 后台配置层（不进代码）：**
- 主题编辑器内容（文案、图片、颜色、字体）→ 存在 `config/settings_data.json`，由 Shopify 管理
- 导航菜单（Navigation）→ Shopify Admin 后台创建
- 商品数据、metafield 值 → Shopify Admin 后台或 API 写入
- App 配置（Klaviyo、GA4）→ 各 App 后台配置

---

## 三、店铺侧技术骨架

### 3.1 整店最小可运行骨架状态

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| **首页（Homepage）** | ✅ 已具备 | `theme/templates/index.json`，8 sections 已配置 |
| **商品详情页 PDP** | ✅ 已具备 | `theme/templates/product-copper-kettle.liquid`，含 sample_verified 熔断 |
| **导航 / 页头 / 页脚** | ✅ 骨架已有，待后台执行 | `theme/config/nav-footer.json`，需在 Shopify Admin > Navigation 创建菜单 |
| **集合页（Collection）** | ❌ 待补 | 当前无集合页模板；单 SKU 阶段可用默认集合页，但需要配置 |
| **政策页（Policy）** | ❌ 待补 | 退换货政策、隐私政策、配送政策；Shopify 内置政策页，需填写内容 |
| **FAQ / 内容页** | ✅ 已具备模板，待后台绑定 | `theme/templates/page.preview-stage.liquid`、`page.research-notes.liquid`、`page.faq.liquid` 已写好；需在 Shopify Admin > Pages 创建句柄并选择模板 |
| **关于页（About）** | ❌ 待补 | 零送样阶段可后置；品牌故事待运营输入 |
| **表单与埋点** | ✅ 骨架已有，待后台执行 | `theme/config/analytics-email.json`，需填入 GA4 Measurement ID |

### 3.2 各模块详细状态

#### 首页
- **已具备**：8 sections（公告条、Hero、信息卡、器型说明、研究记录预告、透明说明区、FAQ、到货通知 CTA）
- **待补**：Hero 主图（运营提供）；Hero 文案（运营确认）
- **需要 UX/运营输入**：Hero 主图（图册主图或占位图）

#### 集合页
- **待补**：Wokiee 主题有默认集合页模板，需要在 Shopify Admin 创建集合并关联商品
- **当前阶段最小操作**：创建一个"全部商品"集合，关联 draft 商品；不需要自定义集合页模板
- **需要 UX/运营输入**：集合名称、集合描述（可后置）

#### 政策页
- **待补**：Shopify 内置政策页（Settings → Policies），需填写：
  - 退换货政策（Refund policy）
  - 隐私政策（Privacy policy）
  - 配送政策（Shipping policy）
  - 服务条款（Terms of service）
- **当前阶段建议**：使用 Shopify 政策生成器生成基础版本，运营确认后发布
- **需要 UX/运营输入**：政策内容确认（可用 Shopify 模板生成，运营审核）

#### FAQ / 内容页
- **已具备**：3 个独立 preview-only 页面模板：
  - `page.preview-stage` → `/pages/preview-stage`
  - `page.research-notes` → `/pages/research-notes`
  - `page.faq` → `/pages/faq`
- **后台执行项**：在 Shopify 页面编辑器创建对应 page handle，并绑定模板；如希望直接使用仓库里的默认正文，页面正文保持空白即可
- **需要 UX/运营输入**：FAQ 内容（已有草稿，运营确认即可）

#### 关于页
- **可后置**：零送样阶段无品牌故事需求
- **需要 UX/运营输入**：品牌故事文案（样品验收后再做）

### 3.3 样品验收后才解锁的模块（不在本阶段）

| 模块 | 解锁条件 |
| --- | --- |
| 购物车 / 结账流程 | `sample_verified=true` + 价格/库存确认 |
| 库存管理 / 物流配置 | 样品验收 + 供应链确认 |
| 实拍图替换 | 样品到手后拍摄 |
| 评论系统 | 有成交后 |
| 多 SKU / 变体 | HTH-220 单 SKU 锁定，禁止引入 |

---

## 四、与 UX / 运营协同接口

### 4.1 技术输入接口分类

| 类型 | 内容 | 运营是否需要接触代码 | 优先级 |
| --- | --- | --- | --- |
| **Schema（技术定义）** | `product-schema.json`（商品字段结构）、metafield 定义 | 否，只需了解字段含义 | 技术侧维护 |
| **Section（主题编辑器配置）** | 首页 8 sections、PDP sections | 否，在 Shopify 主题编辑器直接操作 | 运营可自主操作 |
| **Config（配置文件）** | `nav-footer.json`（导航结构）、`analytics-email.json`（分析配置） | 否，按配置在 Shopify Admin 后台操作 | 技术侧提供，运营执行 |
| **Assets（素材）** | Hero 主图、器型说明图、品牌 logo | 否，上传到 Shopify Files | 运营提供，技术侧挂载 |

### 4.2 运营可自主操作的范围（不需要技术介入）

1. **主题编辑器**（Shopify Admin → Online Store → Themes → Customize）：
   - 修改首页所有 section 的文案和图片
   - 修改颜色、字体等主题设置
   - 调整 section 顺序

2. **商品管理**（Shopify Admin → Products）：
   - 更新商品描述、图片
   - 修改 metafield 值（需要技术侧先定义 metafield schema）

3. **页面管理**（Shopify Admin → Online Store → Pages）：
   - 创建和编辑 `preview-stage`、`research-notes`、`faq` 页面
   - 如需直接使用仓库模板内默认正文，页面正文保持空白
   - 不需要接触代码

4. **政策页**（Shopify Admin → Settings → Policies）：
   - 填写和更新政策内容

### 4.3 需要技术介入的操作

| 操作 | 原因 | 触发条件 |
| --- | --- | --- |
| 修改 PDP 模板逻辑 | 需要改 Liquid 代码 | 样品验收后解锁购买入口 |
| 添加新 section 类型 | 需要写 Liquid section 文件 | 有新的页面结构需求 |
| 修改 metafield schema | 需要在 Shopify Admin 定义新字段 | 新增商品属性 |
| 接入新 App | 需要配置 App + 修改主题代码 | Klaviyo 升级、新分析工具 |
| 修改导航结构 | 需要更新 nav-footer.json 并在后台重建菜单 | 导航层级变化 |

### 4.4 并行执行原则

技术侧和运营侧可以并行推进：
- **技术侧**：接通 Shopify API、创建 draft 商品、设置 metafield、推送 PDP 模板、配置导航
- **运营侧**：准备 Hero 主图、确认 FAQ 文案、填写政策页内容、配置主题编辑器文案

两侧不互相阻塞，技术侧用占位内容先完成结构搭建，运营侧提供真实内容后直接替换。

---

## 五、CEO 汇报：技术主线是否 Ready

### 一句话结论

**技术主线已定义，Capsule Preview 技术侧已就绪；进入"实际启动店铺"阶段的唯一 blocker 是 Shopify API 凭证尚未接入。**

### 当前状态

| 维度 | 状态 | 说明 |
| --- | --- | --- |
| 主题基线 | ✅ Ready | Wokiee Artisan Workshop，GitHub 集成已接通 |
| 首页技术骨架 | ✅ Ready | 8 sections 已配置，等运营提供 Hero 图 |
| PDP 技术骨架 | ✅ Ready | sample_verified 熔断已就绪 |
| FAQ / 内容页模板 | ✅ Ready | `page.preview-stage`、`page.research-notes`、`page.faq` 已写好，待后台创建页面并绑定 |
| 导航 / 页脚 | ✅ 骨架 Ready，待后台执行 | 需在 Shopify Admin 创建菜单 |
| 邮件收集 | ✅ 骨架 Ready，待后台执行 | 需接通 Shopify 原生表单或 Klaviyo |
| GA4 分析 | ✅ 骨架 Ready，待后台执行 | 需填入 Measurement ID |
| Theme 静态校验 | ✅ Ready | `jq` 校验通过，`shopify theme check --path theme` 结果为 `9 files inspected with no offenses found` |
| Shopify API 接入 | ❌ **唯一 Blocker** | 需要 board 提供 Client ID / Client Secret + store domain |
| 集合页 | ⚠️ 可用默认，待配置 | 单 SKU 阶段用默认集合页即可 |
| 政策页 | ⚠️ 待填写 | 需运营填写政策内容 |

### 唯一 Blocker

**Board 需要提供 Shopify Dev Dashboard Client ID / Client Secret 和 store domain。**

有了 API 凭证，技术侧可以：
1. 通过 client credentials 交换 24h access token
2. 通过 API 直接创建 draft 商品（不再依赖 CEO 手动操作）
3. 通过 API 设置 `sample_verified=false` metafield
3. 通过 MCP 在 agent heartbeat 中直接执行 Shopify 操作
4. 消除 Capsule Preview 阶段遗留的所有"需 CEO/运营手动在 Shopify 后台操作"的 blocker

没有 API 凭证，技术侧仍然可以推进主题代码开发，但无法自动化执行 Shopify 后台操作。

### 下一步行动

| 优先级 | 行动 | 负责方 | 阻塞条件 |
| --- | --- | --- | --- |
| P0 | 提供 Shopify Client ID / Client Secret + store domain | Board / CEO | 无阻塞，立即可操作 |
| P1 | 通过 API 创建 draft 商品 + 设置 metafield | CTO | 依赖 P0 |
| P1 | 在 Shopify Admin 创建 `preview-stage` / `research-notes` / `faq` 页面并绑定模板 | CEO / 运营 | 无阻塞 |
| P1 | 在 Shopify Admin 创建导航菜单 | CEO / 运营 | 无阻塞 |
| P1 | 上传 Hero 主图到 Shopify Files | 运营 | 需要图册主图 |
| P2 | 填写政策页内容 | 运营 | 无阻塞 |
| P2 | 配置 GA4 Measurement ID | CEO / 运营 | 需要 GA4 Property |
| P3 | 接通 Klaviyo（升级邮件收集） | CTO + 运营 | 依赖 P0 |

# Preview-only Shopify 后台挂载执行清单

> 对应任务：HTH-265  
> 适用范围：Wokiee Artisan Workshop 预览主题、preview-only + notify-only 页面挂载  
> 目标：把仓库内已完成的首页 / draft PDP / 公开资料页 / 页面模板 / 导航骨架真正绑定到 Shopify 后台可访问入口  
> 最后更新：2026-04-21

## 一、仓库内已就绪的主题资产

以下文件已经在 `theme/` 覆盖层中准备好，不需要再写 Liquid。

| 能力 | 文件 | 说明 |
| --- | --- | --- |
| 首页单品发布型预览结构 | `theme/templates/index.json` | Stage bar、Hero、reason cards、proof strip、object story、specs snapshot、FAQ snapshot、notify CTA |
| draft 商品 PDP | `theme/templates/product-copper-kettle.liquid` | 只给 draft 商品绑定使用，`sample_verified=false` 时隐藏购买入口，只保留通知表单 |
| 公开单品资料页 | `theme/templates/page.copper-kettle-preview.liquid` | 对外访问的单品承接页；底层商品保持 draft 时，前台主入口必须走这里 |
| 当前阶段说明页 | `theme/templates/page.preview-stage.liquid` | 解释 preview-only 边界和样品后解锁条件 |
| Research Notes 页 | `theme/templates/page.research-notes.liquid` | 作为后台支持页面保留，不再作为前台主路径 |
| FAQ 页 | `theme/templates/page.faq.liquid` | 集中承接购买、规格、通知和隐私问题 |
| 页面通用外壳 | `theme/snippets/preview-page-shell.liquid` | 统一内容页版式、颜色和 CTA |
| 单品资料共用组件 | `theme/snippets/preview-product-dossier.liquid` | draft 商品 PDP 与公开资料页复用同一套 notify-only 内容骨架 |
| Launch preview 共享视觉层 | `theme/snippets/preview-launch-theme.liquid` | 共享 typography、chips、buttons、surface tokens |
| 导航 / 页脚配置参考 | `theme/config/nav-footer.json` | 主导航、页脚菜单、页面句柄建议 |

## 二、Shopify 后台执行顺序

### 1. 推送或同步 preview 主题

任选一种方式：

1. 通过 GitHub 集成让 Shopify 拉取 `theme/` 最新改动。
2. 或本地执行 `shopify theme push` 推送到 preview 主题。

完成后，先确认主题里已经出现以下文件对应的模板：

- `product-copper-kettle`
- `page.copper-kettle-preview`
- `page.preview-stage`
- `page.research-notes`
- `page.faq`

### 2. 创建页面并绑定模板

进入 `Shopify Admin > Online Store > Pages`，创建下表中的 4 个页面：

| 页面标题建议 | Handle | 选择模板 | 备注 |
| --- | --- | --- | --- |
| Product Details | `copper-kettle-preview` | `page.copper-kettle-preview` | 对外访问的单品资料页；首页 CTA 和主导航都应指向这里 |
| Preview Terms | `preview-stage` | `page.preview-stage` | 用于页脚和 PDP 顶部入口 |
| Research Notes | `research-notes` | `page.research-notes` | 作为后台支持页保留，不放在前台主导航 |
| FAQ | `faq` | `page.faq` | 用于页脚、PDP 顶部入口和 FAQ 承接 |

重要说明：

- 如果希望直接使用仓库中模板自带的默认正文，页面正文保持空白即可。
- 如果在 Shopify 页面正文里填写内容，当前模板会优先渲染后台正文，等于用后台正文覆盖仓库默认正文。
- 页面创建完成后，前台路由应分别可访问：
  - `/pages/copper-kettle-preview`
  - `/pages/preview-stage`
  - `/pages/research-notes`
  - `/pages/faq`

### 3. 绑定产品模板和 preview 状态

进入 `Shopify Admin > Products`，为紫铜水瓶手冲咖啡壶 draft 商品确认以下设置：

| 项目 | 目标值 |
| --- | --- |
| Product handle | `copper-bottle-pour-over-kettle` |
| Theme template | `product-copper-kettle` |
| Metafield `product_info.sample_verified` | `false` |
| Metafield `product_info.single_sku_locked` | `true` |
| Metafield `product_info.material_note` | `紫铜壶体，非银内壁版本` |

只要 `sample_verified=false`，前台就必须保持 notify-only，不显示价格、库存、购买按钮和变体选择。对外访问不要直接走 `/products/copper-bottle-pour-over-kettle`，而是统一走 `/pages/copper-kettle-preview`。

### 4. 创建主导航和页脚菜单

进入 `Shopify Admin > Online Store > Navigation`，按下表创建：

#### 主导航 `main-menu`

| 顺序 | 标题 | 链接 |
| --- | --- | --- |
| 1 | Home | `/` |
| 2 | Product Details | `/pages/copper-kettle-preview` |
| 3 | FAQ | `/pages/faq` |
| 4 | Notify Me | `/#notify-cta` |

#### 页脚菜单 `footer-menu`

| 顺序 | 标题 | 链接 |
| --- | --- | --- |
| 1 | Preview Terms | `/pages/preview-stage` |
| 2 | FAQ | `/pages/faq` |
| 3 | Privacy Policy | `/policies/privacy-policy` |

### 5. 首页主题编辑器检查

进入 `Shopify Admin > Online Store > Themes > Customize`，核对首页结构：

1. Stage bar
2. Hero
3. Reason cards
4. Proof strip
5. Object story
6. Specs snapshot
7. FAQ snapshot
8. Notify CTA

同时确认：

- Hero 保留两个 CTA：`Notify Me` 和 `See Product Details`
- Hero 图片支持桌面/移动双图槽，且必须带 `Reference image / placeholder` 之类显性角标
- 首屏状态条使用 `Product Preview / Notify Only / Sample Review Pending`
- 首页不再把 `research-notes` 暴露为主路径 CTA

## 三、前台验收清单

完成后台挂载后，至少走一遍以下页面：

| 路径 | 必查项 |
| --- | --- |
| `/` | 首页为 launch-style 单品预览结构；无价格、库存、购买承诺；CTA 指向产品页和通知区 |
| `/pages/copper-kettle-preview` | 页面可访问；无购买按钮；有 FAQ 和通知表单；顶部能跳到 Preview Terms 与 FAQ |
| `/pages/preview-stage` | 页面可访问；内容为阶段说明；CTA 指向产品资料页 |
| `/pages/research-notes` | 页面可访问；作为后台支持页面存在即可，不要求放进前台主导航 |
| `/pages/faq` | 页面可访问；FAQ 分组完整；能返回公开资料页和其他页面 |
| `/products/copper-bottle-pour-over-kettle` | 若商品仍为 draft，则不应作为公开访问入口；仅用于后台 preview 验证 |

所有页面共同红线：

- 不出现价格、库存、交期、预售、预约、候补、锁定名额
- 不出现银内壁、食品级、检测通过、精准控流、专业级表现
- 不把资料图 / 占位图伪装成实拍

## 四、已完成的静态验证

仓库侧已经完成以下检查：

1. `jq empty theme/templates/index.json`
2. `jq empty theme/config/nav-footer.json`
3. `shopify theme check --path theme`

当前 Theme Check 结果：`9 files inspected with no offenses found`

## 五、仍然不在本阶段的事项

以下内容不属于这次挂载范围，不要在后台顺手解锁：

- 把 `sample_verified` 改成 `true`
- 打开 Add to cart、价格、库存、交期
- 增加推荐商品、评论、多 SKU、集合导购
- 把页面写成正式开售、预售、预约或招商语义

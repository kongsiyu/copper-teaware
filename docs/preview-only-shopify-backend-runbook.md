# Preview-only Shopify 后台挂载执行清单

> 对应任务：HTH-265  
> 适用范围：Wokiee Artisan Workshop 预览主题、preview-only + notify-only 页面挂载  
> 目标：把仓库内已完成的首页 / PDP / 页面模板 / 导航骨架真正绑定到 Shopify 后台可访问入口  
> 最后更新：2026-04-21

## 一、仓库内已就绪的主题资产

以下文件已经在 `theme/` 覆盖层中准备好，不需要再写 Liquid。

| 能力 | 文件 | 说明 |
| --- | --- | --- |
| 首页 8 sections | `theme/templates/index.json` | 状态条、Hero、资料卡、器型说明、研究记录预告、透明说明、FAQ、通知 CTA |
| notify-only PDP | `theme/templates/product-copper-kettle.liquid` | `sample_verified=false` 时隐藏购买入口，只保留通知表单 |
| 当前阶段说明页 | `theme/templates/page.preview-stage.liquid` | 解释 preview-only 边界和样品后解锁条件 |
| Research Notes 页 | `theme/templates/page.research-notes.liquid` | 解释资料来源、规格底稿、禁写红线 |
| FAQ 页 | `theme/templates/page.faq.liquid` | 集中承接购买、规格、通知和隐私问题 |
| 页面通用外壳 | `theme/snippets/preview-page-shell.liquid` | 统一页面版式、颜色和 CTA |
| 导航 / 页脚配置参考 | `theme/config/nav-footer.json` | 主导航、页脚菜单、页面句柄建议 |

## 二、Shopify 后台执行顺序

### 1. 推送或同步 preview 主题

任选一种方式：

1. 通过 GitHub 集成让 Shopify 拉取 `theme/` 最新改动。
2. 或本地执行 `shopify theme push` 推送到 preview 主题。

完成后，先确认主题里已经出现以下文件对应的模板：

- `product-copper-kettle`
- `page.preview-stage`
- `page.research-notes`
- `page.faq`

### 2. 创建页面并绑定模板

进入 `Shopify Admin > Online Store > Pages`，创建下表中的 3 个页面：

| 页面标题建议 | Handle | 选择模板 | 备注 |
| --- | --- | --- | --- |
| 资料预览阶段说明 | `preview-stage` | `page.preview-stage` | 用于页脚和 PDP 顶部入口 |
| 当前阶段研究记录 | `research-notes` | `page.research-notes` | 用于首页研究记录预告和主导航 |
| 常见问题 | `faq` | `page.faq` | 用于页脚、PDP 顶部入口和 FAQ 承接 |

重要说明：

- 如果希望直接使用仓库中模板自带的默认正文，页面正文保持空白即可。
- 如果在 Shopify 页面正文里填写内容，当前模板会优先渲染后台正文，等于用后台正文覆盖仓库默认正文。
- 页面创建完成后，前台路由应分别可访问：
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

只要 `sample_verified=false`，前台就必须保持 notify-only，不显示价格、库存、购买按钮和变体选择。

### 4. 创建主导航和页脚菜单

进入 `Shopify Admin > Online Store > Navigation`，按下表创建：

#### 主导航 `main-menu`

| 顺序 | 标题 | 链接 |
| --- | --- | --- |
| 1 | 首页 | `/` |
| 2 | 紫铜咖啡壶 | `/products/copper-bottle-pour-over-kettle` |
| 3 | 研究记录 | `/pages/research-notes` |
| 4 | 到货通知 | `/#notify-cta` |

#### 页脚菜单 `footer-menu`

| 顺序 | 标题 | 链接 |
| --- | --- | --- |
| 1 | 当前阶段说明 | `/pages/preview-stage` |
| 2 | 常见问题 | `/pages/faq` |
| 3 | 隐私说明 | `/policies/privacy-policy` |

### 5. 首页主题编辑器检查

进入 `Shopify Admin > Online Store > Themes > Customize`，核对首页 8 个 section 顺序：

1. Announcement bar
2. Hero
3. Feature cards
4. Image with text
5. Research note preview
6. Transparency section
7. FAQ
8. Email signup

同时确认：

- Hero 只保留一个 CTA：`到货通知我`
- Hero 图片必须带 `占位图`、`资料图` 或 `待实拍` 显性角标
- 首屏状态条使用：`资料预览中 · 仅开放到货通知 · 前台素材均标注资料图 / 占位图`
- 首页研究记录预告按钮正确指向 `/pages/research-notes`

## 三、前台验收清单

完成后台挂载后，至少走一遍以下页面：

| 路径 | 必查项 |
| --- | --- |
| `/` | 首页 8 sections 顺序正确；无价格、库存、购买承诺；研究记录预告可点击 |
| `/products/copper-bottle-pour-over-kettle` | 有样品待验收横幅；无购买按钮；有 FAQ 和通知表单；顶部能跳到 3 个独立页面 |
| `/pages/preview-stage` | 页面可访问；内容为阶段说明；CTA 指回首页通知入口 |
| `/pages/research-notes` | 页面可访问；有规格底稿和禁写红线；CTA 指向产品页通知区 |
| `/pages/faq` | 页面可访问；FAQ 分组完整；能返回产品页和其他页面 |

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

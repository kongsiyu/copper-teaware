# Preview-only 店铺一句话与 Hero 最终交接口径

> 对应任务：[HTH-262](/HTH/issues/HTH-262)
> 决策前提：[HTH-261](/HTH/issues/HTH-261) 已批准
> 适用范围：首页首屏、notify-only PDP、Shopify 原生邮件收集
> 状态：Ready for mount

## 一、店铺一句话

`本店当前关注铜器茶具、咖具与餐具，首期仅开放紫铜水瓶手冲咖啡壶资料预览与到货通知。`

## 二、Hero 最终挂载口径

- 标题：`紫铜水瓶手冲咖啡壶`
- 副标题：`非银内壁版本 · 资料预览阶段`
- 说明：`当前页面仅用于资料预览和到货通知，不开放正式下单。后续如有公开更新，会通过页面或邮件同步。`
- CTA：`到货通知我`
- CTA 链接：`/#notify-cta`
- 次按钮：不保留

### 首屏状态条同步口径

`资料预览中 · 仅开放到货通知 · 前台素材均标注资料图 / 占位图`

## 三、Hero 占位图交接说明

### 当前默认方案

- 当前首屏先用：`占位图`
- 后续在 `sample_verified=false` 阶段允许替换为：`资料图`
- 在真实样品实拍完成并批准前，不允许前台出现无状态标注图片

### 前台可见标注要求

- Hero 图片必须带显性角标：`占位图`、`资料图` 或 `待实拍`
- 角标必须直接做进素材本身，不能只写在后台备注里
- 允许图册图、资料图或安全占位图，但不得修成“像实拍”

### alt / 文件命名建议

- 如果主题支持图片 alt：`紫铜水瓶手冲咖啡壶 Hero 占位图（非实拍）`
- 如果后续替换为资料图：`紫铜水瓶手冲咖啡壶 Hero 资料图（非实拍）`
- 如果当前首页 Hero 不暴露独立 alt 字段，至少保证素材文件名和前台角标都带 `占位图` / `资料图` / `非实拍`

### 禁止项

- 不得去掉状态角标后直接上墙
- 不得写 `实拍`、`上新`、`开售`、`即将可买`
- 不得把资料图裁切或调色成“已完成商品拍摄”观感

## 四、给 CTO / Shopify 后台运营的首屏挂载说明

### 首页字段映射

- `theme/templates/index.json`
  - `announcement-bar.settings.text`：`资料预览中 · 仅开放到货通知 · 前台素材均标注资料图 / 占位图`
  - `hero.settings.heading`：`紫铜水瓶手冲咖啡壶`
  - `hero.settings.subheading`：`非银内壁版本 · 资料预览阶段`
  - `hero.settings.text`：`当前页面仅用于资料预览和到货通知，不开放正式下单。后续如有公开更新，会通过页面或邮件同步。`
  - `hero.settings.button_label`：`到货通知我`
  - `hero.settings.button_link`：`#notify-cta`
  - `hero.settings.second_button_label`：留空
- `theme/templates/product-copper-kettle.liquid`
  - 保持 `sample_verified=false` 时只展示 notify-only 资料页
  - 不在首屏或 PDP 顶部补任何购买型提示

### Shopify 后台执行顺序

1. 在 Shopify Files 上传 Hero 安全占位图或资料图。
2. 在首页 Hero image slot 挂载该图片。
3. 图片前台必须看得到 `占位图` 或 `资料图` 角标；如果主题当前不支持独立状态徽标，就直接把角标做进素材。
4. 首页 Hero 只保留一个 CTA：`到货通知我`。
5. 邮件收集继续用 Shopify 原生表单，不为当前阶段等待 Klaviyo。

### 前台红线

- 只能保留 `preview-only + notify-only` 语义。
- 不得混入价格、库存、交期、预售、预约、候补、购买承诺。
- 不得写 `很快可以买`、`即将开售`、`即将发货`。
- 不得把 `sample_verified=true` 的解锁写成运营侧即将完成事项。
- 不得扩成多 SKU、多版本或正式招商语义。

## 五、Ready / Not Ready

`Ready for mount.`

本包已经给出店铺一句话、Hero 最终口径、占位图交接说明和首屏挂载说明。剩余工作是 Shopify 后台执行，不再是文案待决。

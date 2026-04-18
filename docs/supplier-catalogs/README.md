# 供应商图册目录

存放供应商提供的产品图册、规格书、报价单、认证文件等 PDF 资料。

## 文件命名规范

```
{供应商拼音或英文名}_{资料类型}_{YYYY-MM}.pdf
```

类型缩写：
- `catalog`   — 产品图册
- `spec`      — 规格/参数表
- `price`     — 报价单
- `cert`      — 认证文件（SGS、FDA、CE 等）
- `package`   — 包装说明

示例：
```
tongyi_catalog_2026-04.pdf
jinyuan_price_2026-03.pdf
tongyi_cert_2026-01.pdf
```

## 提交步骤

1. 将 PDF 放入本目录
2. 更新下方 [INDEX.md](INDEX.md) 登记基本信息
3. `git add docs/supplier-catalogs/`
4. `git commit -m "docs: add {供应商} {类型} PDF"`
5. `git push`

> Git LFS 已配置，PDF 文件会自动走大文件通道，无需额外操作。

## 提取内容

提交后运行提取脚本，自动从 PDF 中抽取产品信息：

```bash
python scripts/extract_pdf.py docs/supplier-catalogs/{文件名}.pdf
```

输出结果保存在 `docs/extracted/` 目录，格式为 Markdown，方便后续整理上架。

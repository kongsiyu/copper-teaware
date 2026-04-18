#!/usr/bin/env python3
"""
extract_pdf.py — Extract product info from supplier PDF catalogs.

Usage:
    python scripts/extract_pdf.py docs/supplier-catalogs/foo_catalog_2026-04.pdf
    python scripts/extract_pdf.py docs/supplier-catalogs/  # process all PDFs in dir

Output: docs/extracted/{filename}.md
"""

import sys
import os
import re
from pathlib import Path

OUTPUT_DIR = Path("docs/extracted")


def extract_with_pymupdf(pdf_path: Path) -> str:
    """Extract text using PyMuPDF (fitz). Install: pip install pymupdf"""
    import fitz  # type: ignore
    doc = fitz.open(str(pdf_path))
    pages = []
    for i, page in enumerate(doc, 1):
        text = page.get_text()
        if text.strip():
            pages.append(f"## 第 {i} 页\n\n{text.strip()}")
    return "\n\n---\n\n".join(pages)


def extract_with_pdfplumber(pdf_path: Path) -> str:
    """Fallback extractor using pdfplumber. Install: pip install pdfplumber"""
    import pdfplumber  # type: ignore
    pages = []
    with pdfplumber.open(str(pdf_path)) as pdf:
        for i, page in enumerate(pdf.pages, 1):
            text = page.extract_text() or ""
            tables = page.extract_tables() or []
            parts = []
            if text.strip():
                parts.append(text.strip())
            for table in tables:
                rows = [" | ".join(str(c or "") for c in row) for row in table if row]
                if rows:
                    parts.append("\n".join(rows))
            if parts:
                pages.append(f"## 第 {i} 页\n\n" + "\n\n".join(parts))
    return "\n\n---\n\n".join(pages)


def extract_text(pdf_path: Path) -> str:
    try:
        return extract_with_pymupdf(pdf_path)
    except ImportError:
        pass
    try:
        return extract_with_pdfplumber(pdf_path)
    except ImportError:
        sys.exit(
            "请先安装 PDF 解析库：\n"
            "  pip install pymupdf\n"
            "或\n"
            "  pip install pdfplumber"
        )


def build_markdown(pdf_path: Path, raw_text: str) -> str:
    stem = pdf_path.stem
    parts = stem.split("_")
    supplier = parts[0] if len(parts) > 0 else stem
    doc_type = parts[1] if len(parts) > 1 else "未知"
    date = parts[2] if len(parts) > 2 else "未知"

    header = f"""# {supplier} — {doc_type} ({date})

> 来源文件：`{pdf_path}`
> 提取时间：{__import__('datetime').date.today()}

---

"""
    return header + raw_text


def process_pdf(pdf_path: Path) -> None:
    print(f"处理: {pdf_path}")
    raw = extract_text(pdf_path)
    md = build_markdown(pdf_path, raw)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUTPUT_DIR / (pdf_path.stem + ".md")
    out.write_text(md, encoding="utf-8")
    print(f"  → 已保存: {out}")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    target = Path(sys.argv[1])
    if target.is_dir():
        pdfs = sorted(target.glob("*.pdf")) + sorted(target.glob("*.PDF"))
        if not pdfs:
            print(f"目录 {target} 中没有找到 PDF 文件")
            sys.exit(0)
        for p in pdfs:
            process_pdf(p)
    elif target.is_file():
        process_pdf(target)
    else:
        sys.exit(f"路径不存在: {target}")


if __name__ == "__main__":
    main()

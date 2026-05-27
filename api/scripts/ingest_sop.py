"""
SOP 문서 → ChromaDB ingest 스크립트 (idempotent).

사용법:
    cd api
    python scripts/ingest_sop.py
    python scripts/ingest_sop.py --dry-run
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

DOMAIN_SLUGS: dict[str, str] = {
    "표면처리": "surface_treatment",
    "용접": "welding",
    "절단": "cutting",
    "케이블": "cable",
    "파이프": "pipe",
    "폼스프레이": "foam_spray",
}

DEFECT_SLUGS: dict[str, str] = {
    "균열": "crack",
    "도막떨어짐": "coating_drop",
    "도막분리": "coating_separation",
    "도장흐름": "paint_run",
    "보온재손상": "insulation_damage",
    "스크래치": "scratch",
    "탱크클리닝불량": "tank_cleaning_defect",
    "표면양품": "surface_good",
    "용접불량": "weld_defect",
    "용접블로우홀": "weld_blowhole",
    "용접양품": "weld_good",
    "절단불량": "cut_defect",
    "절단양품": "cut_good",
    "바인딩불량": "binding_defect",
    "바인딩양품": "binding_good",
    "케이블설치불량": "cable_install_defect",
    "케이블설치양품": "cable_install_good",
    "케이블손상": "cable_damage",
    "케이블양품": "cable_good",
    "볼트체결불량": "bolt_defect",
    "볼트체결양품": "bolt_good",
    "폼스프레이불량": "foam_spray_defect",
    "폼스프레이양품": "foam_spray_good",
}

PART_SLUGS: dict[str, str] = {
    "도장": "paint",
    "보온재": "insulation",
    "모재": "base_material",
    "우레탄폼": "urethane_foam",
    "조인트": "joint",
    "케이블타이": "cable_tie",
    "케이블그랜드": "cable_gland",
    "케이블": "cable",
    "파이프": "pipe",
}

SKIP_SECTIONS = {"RAG 검색 키워드"}

SECTION_ORDER = ["결함 개요", "원인", "조치 방법", "주의사항", "참고 기준"]


def to_ontology_id(domain: str, defect: str, part: str) -> str:
    d = DOMAIN_SLUGS.get(domain, domain)
    f = DEFECT_SLUGS.get(defect, defect)
    p = PART_SLUGS.get(part, part)
    return f"{d}.{f}.{p}"


def parse_frontmatter(text: str) -> tuple[dict, str]:
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        return {}, text
    meta = yaml.safe_load(match.group(1))
    body = text[match.end() :]
    return meta, body


def chunk_by_h2(body: str) -> list[tuple[str, str]]:
    """H2 헤딩 기준으로 섹션 분리. (section_name, content) 리스트 반환."""
    sections: list[tuple[str, str]] = []
    current_section: str | None = None
    current_lines: list[str] = []

    for line in body.splitlines():
        h2 = re.match(r"^## (.+)$", line)
        if h2:
            if current_section is not None:
                sections.append((current_section, "\n".join(current_lines).strip()))
            current_section = h2.group(1).strip()
            current_lines = []
        else:
            if current_section is not None:
                current_lines.append(line)

    if current_section is not None:
        sections.append((current_section, "\n".join(current_lines).strip()))

    return [(s, c) for s, c in sections if s not in SKIP_SECTIONS and c]


REQUIRED_FRONTMATTER = {"domain", "defect_name", "part_name"}


def ingest_file(path: Path, collection, *, dry_run: bool) -> int:
    text = path.read_text(encoding="utf-8")
    meta, body = parse_frontmatter(text)

    missing = REQUIRED_FRONTMATTER - set(meta.keys())
    if missing:
        raise ValueError(
            f"{path.name}: frontmatter에 필수 필드 없음 — {sorted(missing)}"
        )

    ontology_id = to_ontology_id(
        meta["domain"],
        meta["defect_name"],
        meta["part_name"],
    )
    sections = chunk_by_h2(body)
    doc_id = path.stem

    for idx, (section, content) in enumerate(sections):
        chunk_id = f"{ontology_id}::{section}"
        if dry_run:
            print(f"  [dry-run] {chunk_id} ({len(content)} chars)")
            continue
        collection.upsert(
            ids=[chunk_id],
            documents=[content],
            metadatas=[
                {
                    "ontology_id": ontology_id,
                    "section": section,
                    "chunk_index": idx,
                    "doc_id": doc_id,
                }
            ],
        )

    return len(sections)


def main() -> None:
    parser = argparse.ArgumentParser(description="SOP 문서를 ChromaDB에 인덱싱합니다.")
    parser.add_argument(
        "--dry-run", action="store_true", help="ingest 없이 청크 목록만 출력"
    )
    args = parser.parse_args()

    docs_root = Path(__file__).resolve().parents[2] / "rag" / "docs"
    md_files = sorted(docs_root.rglob("*.md"))

    if not md_files:
        print(f"[error] SOP 문서가 없습니다: {docs_root}")
        sys.exit(1)

    collection = None
    if not args.dry_run:
        from app.core.chroma import get_sop_collection

        collection = get_sop_collection()

    total_chunks = 0
    for path in md_files:
        count = ingest_file(path, collection, dry_run=args.dry_run)
        total_chunks += count
        print(
            f"{'[dry-run] ' if args.dry_run else ''}✅ {path.parent.name}/{path.name} — {count}개 청크"
        )

    label = "확인" if args.dry_run else "인덱싱"
    print(f"\n총 {len(md_files)}개 문서, {total_chunks}개 청크 {label} 완료")


if __name__ == "__main__":
    main()

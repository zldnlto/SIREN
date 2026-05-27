"""
SOP ingest + retrieval smoke test.

검증 항목:
  - 30개 문서 → 150청크 idempotent ingest
  - ontology_id 메타데이터 필터 정확도
  - chunk_index 오름차순 정렬
  - 존재하지 않는 ID → 빈 리스트
  - 재-ingest 후 중복 청크 없음 (upsert)
  - query_text 전달 시 임베딩 유사도 검색 + chunk_index 정렬 유지
"""

import sys
from pathlib import Path

import chromadb
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

DOCS_ROOT = Path(__file__).resolve().parents[2] / "rag" / "docs"

KNOWN_CASES = [
    (
        "welding.weld_defect.joint",
        ["결함 개요", "원인", "조치 방법", "주의사항", "참고 기준"],
    ),
    ("cutting.cut_defect.base_material", ["결함 개요", "원인", "조치 방법"]),
    ("cable.binding_defect.cable_tie", ["결함 개요", "원인", "조치 방법"]),
]


@pytest.fixture(scope="module")
def populated_collection():
    from scripts.ingest_sop import ingest_file

    client = chromadb.Client()
    collection = client.get_or_create_collection(
        "smoke_test_sop",
        metadata={"hnsw:space": "cosine"},
    )
    total = 0
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        total += ingest_file(path, collection, dry_run=False)
    return collection, total


def test_total_chunk_count(populated_collection):
    _, total = populated_collection
    assert total == 150, f"Expected 150 chunks, got {total}"


@pytest.mark.parametrize("ontology_id,expected_sections", KNOWN_CASES)
def test_retrieval_known_id(populated_collection, ontology_id, expected_sections):
    from app.repositories.sop_repository import get_by_ontology_id

    collection, _ = populated_collection
    chunks = get_by_ontology_id(collection, ontology_id)

    assert len(chunks) > 0, f"No chunks for {ontology_id}"

    for i, chunk in enumerate(chunks):
        assert chunk["chunk_index"] == i, f"chunk_index mismatch at position {i}"

    for chunk in chunks:
        assert chunk["section"], "Empty section name"
        assert chunk[
            "content"
        ].strip(), f"Empty content in section '{chunk['section']}'"

    sections = {c["section"] for c in chunks}
    for s in expected_sections:
        assert s in sections, f"Section '{s}' missing for {ontology_id}"


def test_retrieval_unknown_id(populated_collection):
    from app.repositories.sop_repository import get_by_ontology_id

    collection, _ = populated_collection
    result = get_by_ontology_id(collection, "unknown.does_not.exist")
    assert result == []


def test_retrieval_with_query_text(populated_collection):
    from app.repositories.sop_repository import get_by_ontology_id

    collection, _ = populated_collection
    chunks = get_by_ontology_id(
        collection,
        "welding.weld_defect.joint",
        query_text="용접불량 (조인트)",
    )

    assert len(chunks) > 0, "query_text 모드에서 청크 없음"
    for chunk in chunks:
        assert chunk["section"]
        assert chunk["content"].strip()
    # 문서 순서(chunk_index) 정렬 유지 확인
    indexes = [c["chunk_index"] for c in chunks]
    assert indexes == sorted(indexes), "query 모드에서 chunk_index 정렬 깨짐"


def test_idempotent_reingest(populated_collection):
    from scripts.ingest_sop import ingest_file
    from app.repositories.sop_repository import get_by_ontology_id

    collection, _ = populated_collection
    for path in sorted(DOCS_ROOT.rglob("*.md")):
        ingest_file(path, collection, dry_run=False)

    chunks = get_by_ontology_id(collection, "welding.weld_defect.joint")
    assert len(chunks) > 0
    indexes = [c["chunk_index"] for c in chunks]
    assert len(indexes) == len(set(indexes)), "Duplicate chunk_indexes after re-ingest"

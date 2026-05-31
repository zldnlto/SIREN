"""
재발 방지 harness: CLASS_CODE_MAP ↔ CANONICAL_TO_ONTOLOGY ↔ CANONICAL_TO_DISPLAY_LABEL 일관성 검증

이 테스트가 실패하면 detection.py의 클래스 매핑 딕셔너리 중 하나가
다른 것과 동기화되지 않은 상태다 — 반드시 수정 후 커밋할 것.
"""

from app.domain.detection import (
    CANONICAL_TO_DISPLAY_LABEL,
    CANONICAL_TO_ONTOLOGY,
    CLASS_CODE_MAP,
    build_detection_item,
    canonical_class_for,
    display_label_for,
    ontology_id_for,
)


def test_class_code_map_values_in_ontology():
    """CLASS_CODE_MAP의 모든 canonical_class_name이 CANONICAL_TO_ONTOLOGY에 존재해야 함."""
    missing = [
        name for name in CLASS_CODE_MAP.values() if name not in CANONICAL_TO_ONTOLOGY
    ]
    assert not missing, (
        f"CLASS_CODE_MAP에 있지만 CANONICAL_TO_ONTOLOGY에 없는 클래스: {missing}\n"
        "detection.py의 CANONICAL_TO_ONTOLOGY에 추가하세요."
    )


def test_class_code_map_values_in_display_label():
    """CLASS_CODE_MAP의 모든 canonical_class_name이 CANONICAL_TO_DISPLAY_LABEL에 존재해야 함."""
    missing = [
        name
        for name in CLASS_CODE_MAP.values()
        if name not in CANONICAL_TO_DISPLAY_LABEL
    ]
    assert not missing, (
        f"CLASS_CODE_MAP에 있지만 CANONICAL_TO_DISPLAY_LABEL에 없는 클래스: {missing}\n"
        "detection.py의 CANONICAL_TO_DISPLAY_LABEL에 추가하세요."
    )


def test_ontology_and_display_label_keys_match():
    """CANONICAL_TO_ONTOLOGY와 CANONICAL_TO_DISPLAY_LABEL의 키 세트가 일치해야 함."""
    ontology_keys = set(CANONICAL_TO_ONTOLOGY.keys())
    display_keys = set(CANONICAL_TO_DISPLAY_LABEL.keys())
    only_in_ontology = ontology_keys - display_keys
    only_in_display = display_keys - ontology_keys
    assert (
        not only_in_ontology
    ), f"CANONICAL_TO_ONTOLOGY에만 있는 키: {only_in_ontology}"
    assert (
        not only_in_display
    ), f"CANONICAL_TO_DISPLAY_LABEL에만 있는 키: {only_in_display}"


def test_class_code_map_is_contiguous():
    """CLASS_CODE_MAP의 키가 0부터 연속적인 정수여야 함 (빠진 class_id 없음)."""
    codes = sorted(CLASS_CODE_MAP.keys())
    expected = list(range(len(codes)))
    assert codes == expected, f"CLASS_CODE_MAP 키가 연속적이지 않음: {codes}"


def test_ontology_id_format():
    """CANONICAL_TO_ONTOLOGY 값이 '<domain>.<defect>.<part>' 또는 'background' 형식이어야 함."""
    for name, oid in CANONICAL_TO_ONTOLOGY.items():
        if oid == "background":
            continue
        parts = oid.split(".")
        assert (
            len(parts) == 3
        ), f"{name}: ontology_id '{oid}' 형식 오류 — '<domain>.<defect>.<part>' 이어야 함"


def test_build_detection_item_class_name_overrides_code():
    """class_name 인자가 있으면 CLASS_CODE_MAP을 우회해야 함."""
    item = build_detection_item(
        class_code=0,
        confidence=0.9,
        bbox_raw=[0.1, 0.1, 0.5, 0.5],
        class_name="scratch_paint",
    )
    assert item.canonical_class_name == "scratch_paint"
    assert item.ontology_id == "surface_treatment.scratch.paint"


def test_build_detection_item_fallback_to_code():
    """class_name 인자가 없으면 CLASS_CODE_MAP에서 변환해야 함."""
    expected = canonical_class_for(0)
    item = build_detection_item(
        class_code=0,
        confidence=0.8,
        bbox_raw=[0.0, 0.0, 1.0, 1.0],
    )
    assert item.canonical_class_name == expected


def test_unknown_class_name_falls_back_to_background():
    """CANONICAL_TO_ONTOLOGY에 없는 class_name은 'unknown' ontology_id를 반환해야 함."""
    oid = ontology_id_for("nonexistent_class")
    assert oid == "unknown"


def test_display_label_unknown_returns_class_name():
    """CANONICAL_TO_DISPLAY_LABEL에 없는 class_name은 입력값을 그대로 반환해야 함."""
    result = display_label_for("nonexistent_class")
    assert result == "nonexistent_class"

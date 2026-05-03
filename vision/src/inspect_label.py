# vision/src/inspect_label.py
# 사용법: python vision/src/inspect_label.py
# 목적: TL 라벨 zip 1개를 열어 JSON 구조 자동 분석

import zipfile
import json
from pathlib import Path
from typing import TypedDict, Optional


# ── 경로 설정 ──────────────────────────────────────────────
LABELS_ROOT = Path.home() / "Desktop/Final_PJ/siren-api/vision/data/labels/104.부품_품질_검사_영상_데이터_선박-해양플랜드_고도화_LNG탱크_품질_검사_영상_데이터/3.개방데이터/1.데이터/Training/02.라벨링데이터"

TARGET_ZIP = "TL_표면처리_균열_도장.zip"


# ── 타입 정의 ──────────────────────────────────────────────
class ImageInfo(TypedDict):
    count: int
    sample_keys: list[str]
    sample: dict


class JsonSummary(TypedDict):
    top_level_keys: list[str]
    annotation_type: Optional[str]
    annotation_sample_keys: Optional[list[str]]
    class_info: Optional[list[dict]]
    image_info: Optional[ImageInfo]
    annotation_count: int
    raw_preview: Optional[dict]


# ── 경로 탐색 ──────────────────────────────────────────────
import unicodedata

def find_zip(root: Path, filename: str) -> Optional[Path]:
    """root 하위를 재귀 탐색해 filename과 일치하는 첫 번째 zip 반환"""
    target = unicodedata.normalize("NFC", filename)
    matches = [
        p for p in root.rglob("*.zip")
        if unicodedata.normalize("NFC", p.name) == target
    ]
    if not matches:
        return None
    if len(matches) > 1:
        print(f"⚠️  동일 파일명 {len(matches)}개 발견 — 첫 번째 사용: {matches[0]}")
    return matches[0]


def list_all_zips(root: Path) -> list[Path]:
    """root 하위 전체 zip 목록 반환"""
    return sorted(root.rglob("*.zip"))


# ── 어노테이션 분석 ────────────────────────────────────────
def detect_annotation_type(annotation: dict) -> str:
    """annotation 키 구성으로 라벨 타입 자동 감지"""
    if "segmentation" in annotation and annotation["segmentation"]:
        return "segmentation"
    if "bbox" in annotation and annotation["bbox"]:
        return "bbox"
    return "classification"


def inspect_json(data: dict) -> JsonSummary:
    """JSON 1개의 핵심 구조 요약"""
    summary: JsonSummary = {
        "top_level_keys": list(data.keys()),
        "annotation_type": None,
        "annotation_sample_keys": None,
        "class_info": None,
        "image_info": None,
        "annotation_count": 0,
        "raw_preview": None,
    }

    # COCO 포맷 계열 (images / annotations / categories)
    if "annotations" in data:
        annotations: list[dict] = data["annotations"]
        summary["annotation_count"] = len(annotations)

        if annotations:
            sample_ann = annotations[0]
            summary["annotation_type"] = detect_annotation_type(sample_ann)
            summary["annotation_sample_keys"] = list(sample_ann.keys())

        if "categories" in data:
            cats = data["categories"]
            summary["class_info"] = cats if isinstance(cats, list) else [cats]

        if "images" in data:
            imgs: list[dict] = data["images"]
            img = imgs[0] if imgs else {}
            summary["image_info"] = ImageInfo(
                count=len(imgs),
                sample_keys=list(img.keys()),
                sample=img,
            )

    # 단일 이미지 포맷 (image / label / objects)
    elif "image" in data or "label" in data:
        summary["annotation_type"] = "single_image_format"
        summary["raw_preview"] = {k: data[k] for k in list(data.keys())[:5]}

    return summary


# ── 메인 ───────────────────────────────────────────────────
def main() -> None:
    zip_path = find_zip(LABELS_ROOT, TARGET_ZIP)

    if zip_path is None:
        print(f"❌ '{TARGET_ZIP}' 를 찾을 수 없습니다.")
        print(f"📂 LABELS_ROOT 하위 zip 목록:")
        for f in list_all_zips(LABELS_ROOT):
            print(f"   {f.relative_to(LABELS_ROOT)}")
        return

    print(f"📦 발견: {zip_path.relative_to(LABELS_ROOT)}")
    print("=" * 60)

    with zipfile.ZipFile(zip_path, "r") as zf:
        json_files = [f for f in zf.namelist() if f.endswith(".json")]
        print(f"📄 내부 JSON 파일 수: {len(json_files)}")

        if not json_files:
            print("❌ JSON 파일 없음 — zip 내부 구조:")
            for name in zf.namelist()[:20]:
                print(f"   {name}")
            return

        print("\n📁 내부 디렉토리 구조 (상위 10개):")
        for name in sorted(zf.namelist())[:10]:
            print(f"   {name}")

        target_json = json_files[0]
        print(f"\n🔍 분석 대상 JSON: {target_json}")
        print("-" * 60)

        with zf.open(target_json) as f:
            data = json.load(f)

        summary = inspect_json(data)

        print(f"최상위 키:          {summary['top_level_keys']}")
        print(f"어노테이션 타입:    {summary['annotation_type']}")
        print(f"어노테이션 수:      {summary['annotation_count']}")

        if sample_keys := summary["annotation_sample_keys"]:
            print(f"어노테이션 샘플 키: {sample_keys}")

        if class_info := summary["class_info"]:
            print("\n📌 클래스 목록:")
            for cat in class_info:
                print(f"   {cat}")

        if image_info := summary["image_info"]:
            print(f"\n🖼️  이미지 수:      {image_info['count']}")
            print(f"이미지 샘플 키:    {image_info['sample_keys']}")
            print(f"이미지 샘플:       {image_info['sample']}")

        if raw_preview := summary["raw_preview"]:
            print("\n📋 Raw 미리보기:")
            print(json.dumps(raw_preview, ensure_ascii=False, indent=2))

        print("\n" + "=" * 60)
        print("✅ 분석 완료 — 결과를 공유해주시면 다음 단계 진행합니다.")


if __name__ == "__main__":
    main()
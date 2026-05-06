# vision/src/repair_sample_manifest.py
# 사용법: python vision/src/repair_sample_manifest.py
# 목적:
#   prepare_report.json의 skip/fail 샘플을
#   dataset_index.csv에서 같은 클래스/같은 split의 유효 샘플로 교체 

# 추후 도입하기 - 균열_도장 seed 500개 중 원천 이미지 누락 1건으로 499개 사용중

import csv
import json
import zipfile
import unicodedata
from pathlib import Path
from typing import Optional

BASE_DIR = Path.home() / "Desktop/Final_PJ/siren-api/vision/data"

MANIFEST_PATH = BASE_DIR / "sample_manifest.json"
# MANIFEST_PATH = BASE_DIR / "sample_manifest.repaired.json"

DATASET_INDEX_PATH = BASE_DIR / "dataset_index.csv"
REPORT_PATH = BASE_DIR / "curated" / "prepare_report.json"

LABELS_ROOT = BASE_DIR / "labels"
RAW_ROOT = BASE_DIR / "raw"

OUTPUT_PATH = BASE_DIR / "sample_manifest.repaired.json"
REPAIR_REPORT_PATH = BASE_DIR / "curated" / "repair_report.json"


def find_image(file_name: str, raw_root: Path) -> Optional[Path]:
    matches = list(raw_root.rglob(file_name))
    if matches:
        return matches[0]

    stem = file_name.rsplit(".", 1)[0]
    for ext in [".jpg", ".JPG", ".jpeg", ".JPEG", ".png", ".PNG"]:
        matches = list(raw_root.rglob(stem + ext))
        if matches:
            return matches[0]

    return None


def find_label_json(file_name: str, zip_source: str, labels_root: Path) -> Optional[dict]:
    zip_name = unicodedata.normalize("NFC", zip_source)

    matches = [
        p for p in labels_root.rglob("*.zip")
        if unicodedata.normalize("NFC", p.name) == zip_name
    ]

    if not matches:
        return None

    stem = file_name.rsplit(".", 1)[0]
    json_name = stem + ".json"

    try:
        with zipfile.ZipFile(matches[0], "r") as zf:
            candidates = [
                f for f in zf.namelist()
                if f.endswith(json_name)
            ]

            if not candidates:
                return None

            with zf.open(candidates[0]) as f:
                return json.load(f)

    except zipfile.BadZipFile:
        return None


def is_convertible(json_data: dict, label_type: str) -> bool:
    images = json_data.get("images", [])
    annotations = json_data.get("annotations", [])

    if not images or not annotations:
        return False

    ann = annotations[0]

    if label_type == "segmentation+bbox":
        seg = ann.get("segmentation", [])
        if not seg:
            return False

        points = seg[0] if isinstance(seg[0], list) else seg
        return len(points) >= 6

    if label_type == "bbox":
        bbox = ann.get("bbox", [])
        return len(bbox) == 4

    return True


def is_valid_sample(sample: dict) -> bool:
    file_name = sample["file_name"]
    zip_source = sample["zip_source"]
    label_type = sample["label_type"]

    if find_image(file_name, RAW_ROOT) is None:
        return False

    json_data = find_label_json(file_name, zip_source, LABELS_ROOT)
    if json_data is None:
        return False

    return is_convertible(json_data, label_type)


def same_group(a: dict, b: dict) -> bool:
    return (
        str(a["category_id"]) == str(b["category_id"])
        and a["defect_name"] == b["defect_name"]
        and a["part_name"] == b["part_name"]
        and a["split"] == b["split"]
    )


def load_json(path: Path) -> list | dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_dataset_index(path: Path) -> list[dict]:
    with open(path, "r", encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))

    normalized = []

    for row in rows:
        item = dict(row)

        if "category_id" in item:
            try:
                item["category_id"] = int(item["category_id"])
            except ValueError:
                pass

        normalized.append(item)

    return normalized


def load_broken_samples(report: dict) -> list[dict]:
    return report.get("skipped_samples", []) + report.get("failed_samples", [])


def find_replacement(
    broken: dict,
    candidate_pool: list[dict],
    used_file_names: set[str],
    broken_file_names: set[str],
) -> Optional[dict]:
    candidates = [
        s for s in candidate_pool
        if same_group(broken, s)
        and s["file_name"] not in used_file_names
        and s["file_name"] not in broken_file_names
    ]

    for candidate in candidates:
        if is_valid_sample(candidate):
            return candidate

    return None


def main():
    manifest = load_json(MANIFEST_PATH)
    report = load_json(REPORT_PATH)
    dataset_index = load_dataset_index(DATASET_INDEX_PATH)

    broken_samples = load_broken_samples(report)

    if not broken_samples:
        print("교체할 skip/fail 샘플이 없습니다.")
        return

    broken_file_names = {s["file_name"] for s in broken_samples}

    repaired_manifest = [
        s for s in manifest
        if s["file_name"] not in broken_file_names
    ]

    used_file_names = {s["file_name"] for s in repaired_manifest}

    replacements = []
    unresolved = []

    for broken in broken_samples:
        replacement = find_replacement(
            broken=broken,
            candidate_pool=dataset_index,
            used_file_names=used_file_names,
            broken_file_names=broken_file_names,
        )

        if replacement is None:
            unresolved.append({
                "file_name": broken["file_name"],
                "class": f"{broken['defect_name']}_{broken['part_name']}",
                "category_id": broken["category_id"],
                "split": broken["split"],
                "reason": broken.get("skip_reason") or broken.get("fail_reason"),
            })
            continue

        repaired_manifest.append(replacement)
        used_file_names.add(replacement["file_name"])

        replacements.append({
            "old": broken["file_name"],
            "new": replacement["file_name"],
            "class": f"{broken['defect_name']}_{broken['part_name']}",
            "category_id": broken["category_id"],
            "split": broken["split"],
        })

    repaired_manifest.sort(
        key=lambda s: (
            s["split"],
            int(s["category_id"]),
            s["defect_name"],
            s["part_name"],
            s["file_name"],
        )
    )

    OUTPUT_PATH.write_text(
        json.dumps(repaired_manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    repair_report = {
        "original_manifest_count": len(manifest),
        "broken_count": len(broken_samples),
        "replacement_count": len(replacements),
        "unresolved_count": len(unresolved),
        "repaired_manifest_count": len(repaired_manifest),
        "replacements": replacements,
        "unresolved": unresolved,
        "output_path": str(OUTPUT_PATH),
    }

    REPAIR_REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPAIR_REPORT_PATH.write_text(
        json.dumps(repair_report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print("=" * 60)
    print(f"기존 manifest: {len(manifest)}개")
    print(f"교체 대상: {len(broken_samples)}개")
    print(f"교체 성공: {len(replacements)}개")
    print(f"교체 실패: {len(unresolved)}개")
    print(f"수정 manifest: {OUTPUT_PATH}")
    print(f"수정 리포트: {REPAIR_REPORT_PATH}")

    if replacements:
        print("\n✅ 교체 목록:")
        for item in replacements:
            print(f"- {item['old']} → {item['new']}")

    if unresolved:
        print("\n⚠️ 교체 못 한 샘플:")
        for item in unresolved:
            print(
                f"- {item['file_name']} | "
                f"{item['class']} | "
                f"{item['split']} | "
                f"{item['reason']}"
            )


if __name__ == "__main__":
    main()
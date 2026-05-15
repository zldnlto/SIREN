# vision/src/prepare_yolo_dataset.py

import json
import zipfile
import shutil
import unicodedata
from pathlib import Path
from typing import Optional

# ── 경로 설정 ──────────────────────────────────────────────
BASE_DIR      = Path.home() / "Desktop/Final_PJ/siren-api/vision/data"
MANIFEST_PATH = BASE_DIR / "sample_manifest.json"
LABELS_ROOT   = BASE_DIR / "labels"
RAW_ROOT      = BASE_DIR / "raw"
CURATED_DIR   = BASE_DIR / "curated"

# ── 단일 클래스 모드 ───────────────────────────────────────
SINGLE_CLASS_MODE = True

# ── 카테고리 → YOLO class_id 매핑 ─────────────────────────
CATEGORY_TO_YOLO = {
    1102: 0,  1202: 1,  1101: 2,
    2102: 3,  2202: 4,  2302: 5,  2402: 6,
    2502: 7,  2602: 8,  2702: 9,  2101: 10,
    3102: 11, 3101: 12,
    4102: 13, 4101: 14, 4202: 15, 4201: 16,
    4302: 17, 4301: 18,
    5102: 19, 5101: 20,
    6102: 21, 6101: 22,
}


def get_yolo_class_id(category_id: int) -> int:
    if SINGLE_CLASS_MODE:
        return 0
    return CATEGORY_TO_YOLO.get(category_id, 0)


# ── COCO segmentation → YOLO .txt 변환 ────────────────────
def coco_to_yolo_seg(annotation: dict, img_w: int, img_h: int,
                     yolo_class_id: int) -> Optional[str]:
    seg = annotation.get("segmentation", [])
    if not seg:
        return None

    points = seg[0] if isinstance(seg[0], list) else seg

    if len(points) < 6:
        return None

    normalized = []
    for i in range(0, len(points) - 1, 2):
        normalized += [f"{points[i]/img_w:.6f}", f"{points[i+1]/img_h:.6f}"]

    return f"{yolo_class_id} " + " ".join(normalized)


def coco_to_yolo_bbox(annotation: dict, img_w: int, img_h: int,
                      yolo_class_id: int) -> Optional[str]:
    bbox = annotation.get("bbox", [])
    if not bbox:
        return None

    x, y, w, h = bbox
    cx = (x + w / 2) / img_w
    cy = (y + h / 2) / img_h

    return f"{yolo_class_id} {cx:.6f} {cy:.6f} {w/img_w:.6f} {h/img_h:.6f}"


def convert_json_to_yolo(json_data: dict, category_id: int,
                         label_type: str) -> Optional[str]:
    annotations = json_data.get("annotations", [])
    images      = json_data.get("images", [])

    if not images or not annotations:
        return None

    img           = images[0]
    img_w         = img.get("width", 1)
    img_h         = img.get("height", 1)
    ann           = annotations[0]
    yolo_class_id = get_yolo_class_id(category_id)

    if label_type == "segmentation+bbox":
        return coco_to_yolo_seg(ann, img_w, img_h, yolo_class_id)
    elif label_type == "bbox":
        return coco_to_yolo_bbox(ann, img_w, img_h, yolo_class_id)
    else:
        return f"{yolo_class_id} 0.5 0.5 1.0 1.0"


# ── 이미지 찾기 ────────────────────────────────────────────
def find_image(file_name: str, raw_root: Path) -> Optional[Path]:
    matches = list(raw_root.rglob(file_name))
    if matches:
        return matches[0]
    alt = file_name.replace(".jpg", ".JPG")
    matches = list(raw_root.rglob(alt))
    return matches[0] if matches else None


# ── 라벨 JSON 찾기 ─────────────────────────────────────────
def find_label_json(file_name: str, zip_source: str,
                    labels_root: Path) -> Optional[dict]:
    zip_name = unicodedata.normalize("NFC", zip_source)
    matches  = [
        p for p in labels_root.rglob("*.zip")
        if unicodedata.normalize("NFC", p.name) == zip_name
    ]
    if not matches:
        return None

    stem      = file_name.rsplit(".", 1)[0]
    json_name = stem + ".json"

    with zipfile.ZipFile(matches[0], "r") as zf:
        candidates = [f for f in zf.namelist() if f.endswith(json_name)]
        if not candidates:
            return None
        with zf.open(candidates[0]) as f:
            return json.load(f)


# ── zip 삭제 함수 ──────────────────────────────────────────
def cleanup_raw_zip(zip_name: str) -> None:
    matches = [
        p for p in RAW_ROOT.rglob("*.zip")
        if unicodedata.normalize("NFC", p.name) == zip_name
    ]
    for p in matches:
        size_gb = p.stat().st_size / (1024**3)
        p.unlink()
        print(f"🗑️  삭제 완료: {p.name} ({size_gb:.1f}GB)")


# ── 단일 샘플 처리 ─────────────────────────────────────────
def process_sample(sample: dict) -> dict:
    file_name   = sample["file_name"]
    zip_source  = sample["zip_source"]
    category_id = sample["category_id"]
    label_type  = sample["label_type"]
    defect_name = sample["defect_name"]
    part_name   = sample["part_name"]
    split       = sample["split"]

    class_name = f"{defect_name}_{part_name}"
    split_dir  = "train" if split == "TL" else "val"
    img_dir    = CURATED_DIR / class_name / "images" / split_dir
    label_dir  = CURATED_DIR / class_name / "labels" / split_dir
    img_dir.mkdir(parents=True, exist_ok=True)
    label_dir.mkdir(parents=True, exist_ok=True)

    result = {"file_name": file_name, "status": "skip", "reason": ""}

    # 이미 처리된 파일 스킵
    img_dest   = img_dir / file_name
    label_stem = file_name.rsplit(".", 1)[0]
    label_dest = label_dir / f"{label_stem}.txt"
    if img_dest.exists() and label_dest.exists():
        result["reason"] = "이미 처리됨"
        return result

    # 이미지 복사
    img_path = find_image(file_name, RAW_ROOT)
    if img_path is None:
        result["reason"] = "이미지 없음"
        return result

    shutil.copy2(img_path, img_dest)

    # 라벨 변환
    json_data = find_label_json(file_name, zip_source, LABELS_ROOT)
    if json_data is None:
        result["reason"] = "라벨 JSON 없음"
        return result

    yolo_txt = convert_json_to_yolo(json_data, category_id, label_type)
    if yolo_txt is None:
        result["reason"] = "변환 실패"
        return result

    label_dest.write_text(yolo_txt)
    result["status"] = "ok"
    return result


# ── 메인 ───────────────────────────────────────────────────
def main(target_class: Optional[str] = None, delete_zip: bool = False):
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    if target_class:
        manifest = [
            s for s in manifest
            if f"{s['defect_name']}_{s['part_name']}" == target_class
        ]
        print(f"대상 클래스: {target_class} ({len(manifest)}개)")
        print(f"SINGLE_CLASS_MODE: {SINGLE_CLASS_MODE}")

    success = fail = skip_exists = skip_no_img = 0

    for i, sample in enumerate(manifest, 1):
        res = process_sample(sample)

        if res["status"] == "ok":
            success += 1
        elif res["reason"] == "이미 처리됨":
            skip_exists += 1
        elif res["reason"] == "이미지 없음":
            skip_no_img += 1
        else:
            fail += 1
            print(f"  ❌ {res['file_name']}: {res['reason']}")

        if i % 100 == 0:
            print(f"[{i}/{len(manifest)}] "
                  f"✅{success} "
                  f"⏭️ 기존:{skip_exists} "
                  f"⚠️ 이미지없음:{skip_no_img} "
                  f"❌{fail}")

    print("=" * 60)
    print(f"신규 처리:   {success}개")
    print(f"이미 있음:   {skip_exists}개")
    print(f"이미지 없음: {skip_no_img}개")
    print(f"실패:        {fail}개")
    print(f"저장 위치:   {CURATED_DIR}")

    if delete_zip and target_class:
        zip_sources = {s["zip_source"] for s in manifest}
        ts_zips = {
            z.replace("TL_", "TS_").replace("VL_", "VS_")
            for z in zip_sources
        }
        print(f"\n🗑️  삭제 대상 zip: {ts_zips}")
        for zip_name in ts_zips:
            cleanup_raw_zip(zip_name)
    elif delete_zip:
        print("⚠️  전체 모드에서는 삭제 불가")


if __name__ == "__main__":
    main(target_class="균열_보온재", delete_zip=False)
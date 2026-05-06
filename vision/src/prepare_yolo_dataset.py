# vision/src/prepare_yolo_dataset.py
# 사용법: python vision/src/prepare_yolo_dataset.py
# 목적: sample_manifest.json 기반으로
#       이미지 추출 + YOLO seg 포맷 변환

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

# ── 카테고리 → YOLO class_id 매핑 ─────────────────────────
CATEGORY_TO_YOLO = {
    1102: 0,   # 용접불량
    1202: 1,   # 용접블로우홀
    1101: 2,   # 용접양품
    2102: 3,   # 균열
    2202: 4,   # 도장흐름
    2302: 5,   # 도막떨어짐
    2402: 6,   # 도막분리
    2502: 7,   # 스크래치
    2602: 8,   # 보온재손상
    2702: 9,   # 탱크클리닝불량
    2101: 10,  # 표면양품
    3102: 11,  # 볼트체결불량
    3101: 12,  # 볼트체결양품
    4102: 13,  # 케이블설치불량
    4101: 14,  # 케이블설치양품
    4202: 15,  # 케이블손상
    4201: 16,  # 케이블양품
    4302: 17,  # 바인딩불량
    4301: 18,  # 바인딩양품
    5102: 19,  # 절단불량
    5101: 20,  # 절단양품
    6102: 21,  # 폼스프레이불량
    6101: 22,  # 폼스프레이양품
}


# ── COCO segmentation → YOLO .txt 변환 ────────────────────
def coco_to_yolo_seg(annotation: dict, img_w: int, img_h: int,
                     yolo_class_id: int) -> Optional[str]:
    """
    COCO segmentation → YOLO seg 포맷
    출력: "class_id x1 y1 x2 y2 ... (정규화)"
    """
    seg = annotation.get("segmentation", [])
    if not seg:
        return None

    points = seg[0]  # [[x1,y1,x2,y2,...]]
    if len(points) < 6:
        return None

    normalized = []
    for i in range(0, len(points), 2):
        x = points[i]   / img_w
        y = points[i+1] / img_h
        normalized += [f"{x:.6f}", f"{y:.6f}"]

    return f"{yolo_class_id} " + " ".join(normalized)


def coco_to_yolo_bbox(annotation: dict, img_w: int, img_h: int,
                      yolo_class_id: int) -> Optional[str]:
    """
    COCO bbox → YOLO det 포맷
    출력: "class_id cx cy w h (정규화)"
    """
    bbox = annotation.get("bbox", [])
    if not bbox:
        return None

    x, y, w, h = bbox
    cx = (x + w / 2) / img_w
    cy = (y + h / 2) / img_h
    nw = w / img_w
    nh = h / img_h

    return f"{yolo_class_id} {cx:.6f} {cy:.6f} {nw:.6f} {nh:.6f}"


def convert_json_to_yolo(json_data: dict, yolo_class_id: int,
                          label_type: str) -> Optional[str]:
    """JSON 1개 → YOLO .txt 1개"""
    annotations = json_data.get("annotations", [])
    images      = json_data.get("images", [])

    if not images or not annotations:
        return None

    img     = images[0]
    img_w   = img.get("width", 1)
    img_h   = img.get("height", 1)
    ann     = annotations[0]

    if label_type == "segmentation+bbox":
        return coco_to_yolo_seg(ann, img_w, img_h, yolo_class_id)
    elif label_type == "bbox":
        return coco_to_yolo_bbox(ann, img_w, img_h, yolo_class_id)
    else:
        # classification → 빈 파일 (배경 아닌 전체 이미지)
        return f"{yolo_class_id} 0.5 0.5 1.0 1.0"


# ── 이미지 찾기 ────────────────────────────────────────────
def find_image(file_name: str, raw_root: Path) -> Optional[Path]:
    """raw/ 하위에서 file_name 탐색"""
    matches = list(raw_root.rglob(file_name))
    if matches:
        return matches[0]
    # 확장자 대소문자 변환
    alt = file_name.replace(".jpg", ".JPG")
    matches = list(raw_root.rglob(alt))
    return matches[0] if matches else None


# ── 라벨 JSON 찾기 ─────────────────────────────────────────
def find_label_json(file_name: str, zip_source: str,
                    labels_root: Path) -> Optional[dict]:
    """TL_*.zip에서 file_name 기반 JSON 찾기"""
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
        candidates = [f for f in zf.namelist()
                      if f.endswith(json_name)]
        if not candidates:
            return None
        with zf.open(candidates[0]) as f:
            import json
            return json.load(f)


# ── 단일 샘플 처리 ─────────────────────────────────────────
def process_sample(sample: dict) -> dict:
    file_name   = sample["file_name"]
    zip_source  = sample["zip_source"]
    category_id = sample["category_id"]
    label_type  = sample["label_type"]
    defect_name = sample["defect_name"]
    part_name   = sample["part_name"]
    split       = sample["split"]

    class_name    = f"{defect_name}_{part_name}"
    yolo_class_id = CATEGORY_TO_YOLO.get(category_id, 0)

    # 출력 경로
    split_dir  = "train" if split == "TL" else "val"
    img_dir    = CURATED_DIR / class_name / "images" / split_dir
    label_dir  = CURATED_DIR / class_name / "labels" / split_dir
    img_dir.mkdir(parents=True, exist_ok=True)
    label_dir.mkdir(parents=True, exist_ok=True)

    result = {"file_name": file_name, "status": "skip",
              "reason": ""}

    # 이미지 복사
    img_path = find_image(file_name, RAW_ROOT)
    if img_path is None:
        result["reason"] = "이미지 없음"
        return result

    shutil.copy2(img_path, img_dir / file_name)

    # 라벨 변환
    json_data = find_label_json(file_name, zip_source, LABELS_ROOT)
    if json_data is None:
        result["reason"] = "라벨 JSON 없음"
        return result

    yolo_txt = convert_json_to_yolo(json_data, yolo_class_id, label_type)
    if yolo_txt is None:
        result["reason"] = "변환 실패"
        return result

    label_stem = file_name.rsplit(".", 1)[0]
    (label_dir / f"{label_stem}.txt").write_text(yolo_txt)

    result["status"] = "ok"
    return result


# ── 메인 ───────────────────────────────────────────────────
def main(target_class: Optional[str] = None):
    """
    target_class: None이면 전체, 있으면 해당 클래스만
    예: main("균열_도장")
    """
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        import json
        manifest = json.load(f)

    if target_class:
        manifest = [
            s for s in manifest
            if f"{s['defect_name']}_{s['part_name']}" == target_class
        ]
        print(f"대상 클래스: {target_class} ({len(manifest)}개)")

    success = fail = skip = 0

    for i, sample in enumerate(manifest, 1):
        res = process_sample(sample)
        if res["status"] == "ok":
            success += 1
        elif res["status"] == "skip":
            skip += 1
            if i <= 5 or res["reason"] != "이미지 없음":
                print(f"  ⚠️  {res['file_name']}: {res['reason']}")
        else:
            fail += 1

        if i % 100 == 0:
            print(f"[{i}/{len(manifest)}] ✅{success} ⚠️{skip} ❌{fail}")

    print("=" * 60)
    print(f"완료: {success}개 / 스킵: {skip}개 / 실패: {fail}개")
    print(f"저장 위치: {CURATED_DIR}")


if __name__ == "__main__":
    # 균열_도장 단일 클래스 테스트
    main(target_class="균열_도장")
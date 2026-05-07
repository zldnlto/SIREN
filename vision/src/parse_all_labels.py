# vision/src/parse_all_labels.py
# 사용법: python vision/src/parse_all_labels.py
# 목적: TL_* / VL_* 전체 zip 파싱
#       → dataset_index.csv + label_report.md + 노션 입력용 로그 출력

import zipfile
import json
import csv
import unicodedata
from pathlib import Path
from collections import defaultdict
from typing import Optional

# ── 경로 설정 ──────────────────────────────────────────────
LABELS_ROOT = Path.home() / "Desktop/Final_PJ/siren-api/vision/data/labels"
OUTPUT_DIR  = Path.home() / "Desktop/Final_PJ/siren-api/vision/data"
OUTPUT_CSV  = OUTPUT_DIR / "dataset_index.csv"
REPORT_PATH = OUTPUT_DIR / "label_report.md"
NOTION_LOG  = OUTPUT_DIR / "notion_log.txt"

# ── 카테고리 매핑 ──────────────────────────────────────────
CATEGORY_MAP = {
    1101: ("용접",     "용접양품"),
    1102: ("용접",     "용접불량"),
    1202: ("용접",     "용접블로우홀"),
    2101: ("표면처리", "표면양품"),
    2102: ("표면처리", "균열"),
    2202: ("표면처리", "도장흐름"),
    2302: ("표면처리", "도막떨어짐"),
    2402: ("표면처리", "도막분리"),
    2502: ("표면처리", "스크래치"),
    2602: ("표면처리", "보온재손상"),
    2702: ("표면처리", "탱크클리닝불량"),
    3101: ("파이프",   "볼트체결양품"),
    3102: ("파이프",   "볼트체결불량"),
    4101: ("케이블",   "케이블설치양품"),
    4102: ("케이블",   "케이블설치불량"),
    4201: ("케이블",   "케이블양품"),
    4202: ("케이블",   "케이블손상"),
    4301: ("케이블",   "바인딩양품"),
    4302: ("케이블",   "바인딩불량"),
    5101: ("절단",     "절단양품"),
    5102: ("절단",     "절단불량"),
    6101: ("폼스프레이", "폼스프레이양품"),
    6102: ("폼스프레이", "폼스프레이불량"),
}

VALID_CATEGORY_IDS = set(CATEGORY_MAP.keys())


# ── 파일명 파싱 ────────────────────────────────────────────
def parse_zip_name(zip_name: str) -> dict:
    stem  = zip_name.replace(".zip", "")
    parts = stem.split("_", 3)
    return {
        "split":       parts[0] if len(parts) > 0 else "",
        "domain":      parts[1] if len(parts) > 1 else "",
        "defect_name": parts[2] if len(parts) > 2 else "",
        "part_name":   parts[3] if len(parts) > 3 else "",
    }


# ── 어노테이션 타입 감지 ───────────────────────────────────
def detect_label_type(annotation: dict) -> str:
    has_seg  = bool(annotation.get("segmentation"))
    has_bbox = bool(annotation.get("bbox"))
    if has_seg and has_bbox:
        return "segmentation+bbox"
    if has_seg:
        return "segmentation"
    if has_bbox:
        return "bbox"
    return "classification"


# ── 품질 체크 ──────────────────────────────────────────────
def check_quality(data: dict) -> dict:
    issues      = []
    annotations = data.get("annotations", [])
    images      = data.get("images", [])

    image_ids     = {img["id"] for img in images}
    ann_image_ids = {ann["image_id"] for ann in annotations}

    no_ann = image_ids - ann_image_ids
    if no_ann:
        issues.append(f"어노테이션 없는 이미지 {len(no_ann)}개")

    empty_bbox = sum(1 for a in annotations if not a.get("bbox"))
    empty_seg  = sum(1 for a in annotations if not a.get("segmentation"))
    if empty_bbox:
        issues.append(f"bbox 비어있음 {empty_bbox}개")
    if empty_seg:
        issues.append(f"segmentation 비어있음 {empty_seg}개")

    zero_area = sum(1 for a in annotations if a.get("area", 1) <= 0)
    if zero_area:
        issues.append(f"area=0 이하 {zero_area}개")

    tiny_bbox = sum(
        1 for a in annotations
        if a.get("bbox") and (a["bbox"][2] < 10 or a["bbox"][3] < 10)
    )
    if tiny_bbox:
        issues.append(f"bbox 10px 이하 {tiny_bbox}개")

    ann_map = defaultdict(list)
    for a in annotations:
        ann_map[a.get("image_id")].append(a.get("category_id"))
    duplicates = sum(
        1 for cats in ann_map.values()
        if len(cats) != len(set(cats))
    )
    if duplicates:
        issues.append(f"중복 어노테이션 이미지 {duplicates}개")

    invalid_ids = {
        a.get("category_id") for a in annotations
        if a.get("category_id") not in VALID_CATEGORY_IDS
    }
    if invalid_ids:
        issues.append(f"유효하지 않은 category_id {invalid_ids}")

    return {"clean": len(issues) == 0, "issues": issues}


# ── 단일 JSON 파싱 ─────────────────────────────────────────
def parse_json(data: dict, zip_info: dict) -> list[dict]:
    rows        = []
    annotations = data.get("annotations", [])
    images      = data.get("images", [])
    image_map   = {img["id"]: img for img in images}

    for ann in annotations:
        image_id    = ann.get("image_id")
        category_id = ann.get("category_id")
        img         = image_map.get(image_id, {})
        domain, defect_name = CATEGORY_MAP.get(category_id, ("", ""))

        rows.append({
            "file_name":     img.get("file_name", ""),
            "split":         zip_info["split"],
            "domain":        domain or zip_info["domain"],
            "defect_name":   defect_name or zip_info["defect_name"],
            "part_name":     zip_info["part_name"],
            "category_id":   category_id,
            "label_type":    detect_label_type(ann),
            "width":         img.get("width", ""),
            "height":        img.get("height", ""),
            "date_captured": img.get("date_captured", ""),
            "area":          ann.get("area", ""),
            "zip_source":    zip_info["zip_name"],
        })
    return rows


# ── zip 1개 처리 ───────────────────────────────────────────
def process_zip(zip_path: Path) -> dict:
    zip_name = unicodedata.normalize("NFC", zip_path.name)
    zip_info = parse_zip_name(zip_name)
    zip_info["zip_name"] = zip_name

    result = {
        "zip_name":          zip_name,
        "split":             zip_info["split"],
        "domain":            zip_info["domain"],
        "defect_name":       zip_info["defect_name"],
        "part_name":         zip_info["part_name"],
        "image_count":       0,
        "label_type":        set(),
        "resolution":        set(),
        "category_ids_used": set(),
        "defect_count":      0,
        "good_count":        0,
        "date_range":        [],
        "quality":           {"clean": True, "issues": []},
        "rows":              [],
        "error":             None,
    }

    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            json_files = [f for f in zf.namelist() if f.endswith(".json")]
            result["image_count"] = len(json_files)
            quality_checked = False

            for jf in json_files:
                with zf.open(jf) as f:
                    data = json.load(f)

                if not quality_checked:
                    result["quality"] = check_quality(data)
                    quality_checked   = True

                rows = parse_json(data, zip_info)
                result["rows"].extend(rows)

                for row in rows:
                    result["label_type"].add(row["label_type"])
                    if row["width"] and row["height"]:
                        result["resolution"].add(
                            f"{row['width']}x{row['height']}"
                        )
                    if row["category_id"]:
                        result["category_ids_used"].add(row["category_id"])
                    if row["date_captured"]:
                        result["date_range"].append(row["date_captured"])

                    cat = row.get("category_id", 0) or 0
                    if cat % 10 == 1:
                        result["good_count"] += 1
                    elif cat % 10 == 2:
                        result["defect_count"] += 1

    except Exception as e:
        result["error"] = str(e)

    return result


# ── 노션 출력 포맷 ─────────────────────────────────────────
def format_notion_row(res: dict) -> str:
    label_types = "/".join(sorted(res["label_type"]))
    resolutions = "/".join(sorted(res["resolution"]))
    total       = res["good_count"] + res["defect_count"]
    good_ratio  = f"{res['good_count']/total*100:.0f}%" if total > 0 else "-"

    date_range = "-"
    if res["date_range"]:
        dates      = sorted(res["date_range"])
        date_range = f"{dates[0][:7]} ~ {dates[-1][:7]}"

    quality_str = "✅ 없음" if res["quality"]["clean"] else "⚠️ 있음"
    issue_str   = " / ".join(res["quality"]["issues"]) if res["quality"]["issues"] else "-"
    bbox_issue  = "⚠️ 있음" if any("bbox" in i for i in res["quality"]["issues"]) else "✅ 없음"
    dup_issue   = "⚠️ 있음" if any("중복" in i for i in res["quality"]["issues"]) else "✅ 없음"

    return (
        f"\n{'='*60}\n"
        f"📋 노션 입력용\n"
        f"{'='*60}\n"
        f"이름:           {res['zip_name'].replace('.zip','')}\n"
        f"상태:           완료\n"
        f"split:          {res['split']}\n"
        f"이미지수:       {res['image_count']:,}\n"
        f"라벨타입:       {label_types}\n"
        f"해상도:         {resolutions}\n"
        f"양품수:         {res['good_count']:,}\n"
        f"불량수:         {res['defect_count']:,}\n"
        f"양품비율:       {good_ratio}\n"
        f"촬영기간:       {date_range}\n"
        f"결측여부:       {quality_str}\n"
        f"결측내용:       {issue_str}\n"
        f"bbox이상:       {bbox_issue}\n"
        f"중복어노테이션: {dup_issue}\n"
        f"특이사항:       \n"
        f"{'='*60}"
    )


# ── 리포트 작성 ────────────────────────────────────────────
def write_report(zip_results: list[dict], all_rows: list[dict]) -> None:
    lines = ["# SIREN 라벨 분석 리포트\n"]

    total_images = sum(r["image_count"] for r in zip_results)
    total_defect = sum(r["defect_count"] for r in zip_results)
    total_good   = sum(r["good_count"]   for r in zip_results)
    issue_zips   = [r for r in zip_results if not r["quality"]["clean"]]

    lines += [
        "## 전체 요약\n",
        f"- 총 zip 수: {len(zip_results)}개",
        f"- 총 이미지 수: {total_images:,}개",
        f"- 총 불량 수: {total_defect:,}개",
        f"- 총 양품 수: {total_good:,}개",
        f"- 품질 이슈 zip: {len(issue_zips)}개\n",
    ]

    domain_counts = defaultdict(int)
    for row in all_rows:
        domain_counts[row["domain"]] += 1

    lines += ["\n## 도메인별 이미지 수\n"]
    for domain, count in sorted(domain_counts.items(), key=lambda x: -x[1]):
        lines.append(f"- {domain}: {count:,}개")

    combo_counts = defaultdict(int)
    for row in all_rows:
        key = f"{row['defect_name']}_{row['part_name']}"
        combo_counts[key] += 1

    lines += ["\n## defect_name × part_name 조합\n"]
    for combo, count in sorted(combo_counts.items(), key=lambda x: -x[1]):
        lines.append(f"- {combo}: {count:,}개")

    label_type_counts = defaultdict(int)
    for row in all_rows:
        label_type_counts[row["label_type"]] += 1

    lines += ["\n## 라벨 타입 분포\n"]
    for lt, count in sorted(label_type_counts.items(), key=lambda x: -x[1]):
        lines.append(f"- {lt}: {count:,}개")

    if issue_zips:
        lines += ["\n## 품질 이슈 목록\n"]
        for r in issue_zips:
            lines += [f"### {r['zip_name']}"]
            for issue in r["quality"]["issues"]:
                lines += [f"- {issue}"]

    lines += [
        "\n## zip별 상세\n",
        "| zip명 | split | 이미지수 | 라벨타입 | 양품 | 불량 | 품질 |",
        "|-------|-------|---------|---------|-----|-----|-----|",
    ]
    for r in zip_results:
        label_types = "/".join(sorted(r["label_type"]))
        quality     = "🟢" if r["quality"]["clean"] else "⚠️"
        name        = (r["zip_name"].replace(".zip", "")
                       .replace("TL_", "").replace("VL_", ""))
        lines.append(
            f"| {name} | {r['split']} | {r['image_count']:,} | "
            f"{label_types} | {r['good_count']:,} | "
            f"{r['defect_count']:,} | {quality} |"
        )

    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ── 메인 ───────────────────────────────────────────────────
def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    all_zips = sorted(
        p for p in LABELS_ROOT.rglob("*.zip")
        if unicodedata.normalize("NFC", p.name).startswith(("TL_", "VL_"))
    )

    print(f"총 {len(all_zips)}개 zip 발견")
    print("=" * 60)

    all_rows     = []
    zip_results  = []
    notion_lines = []

    for i, zp in enumerate(all_zips, 1):
        name = unicodedata.normalize("NFC", zp.name)
        print(f"[{i:02d}/{len(all_zips)}] {name} 처리 중...")

        res = process_zip(zp)
        zip_results.append(res)
        all_rows.extend(res["rows"])

        status  = "✅" if res["error"] is None else f"❌ {res['error']}"
        quality = ("🟢 정상" if res["quality"]["clean"]
                   else f"⚠️  {res['quality']['issues']}")

        print(f"  {status} 이미지수: {res['image_count']:,} | "
              f"라벨타입: {res['label_type']} | "
              f"품질: {quality}")

        notion_row = format_notion_row(res)
        print(notion_row)
        notion_lines.append(notion_row)

    if all_rows:
        fieldnames = [
            "file_name", "split", "domain", "defect_name",
            "part_name", "category_id", "label_type",
            "width", "height", "date_captured", "area", "zip_source",
        ]
        with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_rows)
        print(f"\n✅ CSV 저장 완료: {OUTPUT_CSV}")
        print(f"   총 {len(all_rows):,}개 row")

    write_report(zip_results, all_rows)
    print(f"✅ 리포트 저장 완료: {REPORT_PATH}")

    with open(NOTION_LOG, "w", encoding="utf-8") as f:
        f.write("\n".join(notion_lines))
    print(f"✅ 노션 로그 저장 완료: {NOTION_LOG}")


if __name__ == "__main__":
    main()
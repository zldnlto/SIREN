# vision/src/create_sample_manifest.py
# 사용법: python vision/src/create_sample_manifest.py
# 목적: dataset_index.csv 기반으로 sample_manifest.json 생성
#       표면처리 전체 클래스 × 클래스당 500장 (TL) / 100장 (VL)

import json
import pandas as pd
from pathlib import Path

# ── 경로 설정 ──────────────────────────────────────────────
CSV_PATH      = Path.home() / "Desktop/Final_PJ/siren-api/vision/data/dataset_index.csv"
OUTPUT_DIR    = Path.home() / "Desktop/Final_PJ/siren-api/vision/data"
MANIFEST_PATH = OUTPUT_DIR / "sample_manifest.json"

SEED            = 42
N_TRAIN_SAMPLES = 500
N_VAL_SAMPLES   = 100

# ── TS_* 파일키 매핑 ───────────────────────────────────────
SOURCE_KEY_MAP = {
    "TL_표면처리_균열_도장":        "526047",
    "TL_표면처리_균열_보온재":      "526048",
    "TL_표면처리_도막떨어짐_도장":  "526049",
    "TL_표면처리_도막분리_도장":    "526050",
    "TL_표면처리_도장흐름_도장":    "526051",
    "TL_표면처리_보온재손상_보온재": "526052",
    "TL_표면처리_스크래치_도장":    "526053",
    "TL_표면처리_스크래치_모재":    "526054",
    "TL_표면처리_스크래치_보온재":  "526055",
    "TL_표면처리_탱크클리닝불량_모재": "526056",
    "TL_표면처리_표면양품_도장":    "526057",
    "TL_표면처리_표면양품_모재":    "526058",
    "TL_표면처리_표면양품_보온재":  "526059",
    "VL_표면처리_균열_도장":        "526107",
    "VL_표면처리_균열_보온재":      "526108",
    "VL_표면처리_도막떨어짐_도장":  "526109",
    "VL_표면처리_도막분리_도장":    "526110",
    "VL_표면처리_도장흐름_도장":    "526111",
    "VL_표면처리_보온재손상_보온재": "526112",
    "VL_표면처리_스크래치_도장":    "526113",
    "VL_표면처리_스크래치_모재":    "526114",
    "VL_표면처리_스크래치_보온재":  "526115",
    "VL_표면처리_탱크클리닝불량_모재": "526116",
    "VL_표면처리_표면양품_도장":    "526117",
    "VL_표면처리_표면양품_모재":    "526118",
    "VL_표면처리_표면양품_보온재":  "526119",
}

# ── 도메인-부품 유효성 검증 ────────────────────────────────
VALID_COMBOS = {
    "용접":      ["조인트"],
    "절단":      ["모재", "보온재"],
    "케이블":    ["케이블타이", "케이블그랜드", "케이블"],
    "파이프":    ["파이프"],
    "폼스프레이": ["우레탄폼"],
    "표면처리":  ["도장", "모재", "보온재"],
}

VALID_DEFECTS = {
    "용접":      ["용접불량", "용접블로우홀", "용접양품"],
    "절단":      ["절단불량", "절단양품"],
    "케이블":    ["바인딩불량", "바인딩양품", "케이블설치불량",
                  "케이블설치양품", "케이블손상", "케이블양품"],
    "파이프":    ["볼트체결불량", "볼트체결양품"],
    "폼스프레이": ["폼스프레이불량", "폼스프레이양품"],
    "표면처리":  ["균열", "도막떨어짐", "도막분리", "도장흐름",
                  "보온재손상", "스크래치", "탱크클리닝불량", "표면양품"],
}


def get_source_key(zip_source: str) -> str:
    source_name = zip_source.replace(".zip", "")
    return SOURCE_KEY_MAP.get(source_name, "")


def build_manifest_item(row, split: str) -> dict:
    return {
        "file_name":        row["file_name"],
        "zip_source":       row["zip_source"],
        "source_key":       get_source_key(row["zip_source"]),
        "domain":           row["domain"],
        "defect_name":      row["defect_name"],
        "part_name":        row["part_name"],
        "category_id":      int(row["category_id"]),
        "label_type":       row["label_type"],
        "split":            split,
        "difficulty_score": None,
        "sample_type":      None,
        "input_size":       640,
    }


def main():
    df = pd.read_csv(CSV_PATH)
    print(f"전체 데이터: {len(df):,}개")

    # 이상치 제거
    df_clean = df[
        df.apply(lambda x:
            x["defect_name"] in VALID_DEFECTS.get(x["domain"], []) and
            x["part_name"]   in VALID_COMBOS.get(x["domain"], []),
            axis=1
        )
    ]
    print(f"정제 후:    {len(df_clean):,}개")

    # 표면처리 전체 클래스
    df_target = df_clean[df_clean["domain"] == "표면처리"]
    print(f"표면처리:   {len(df_target):,}개")

    tl = df_target[df_target["split"] == "TL"]
    vl = df_target[df_target["split"] == "VL"]

    manifest = []
    stats    = []

    # TL 샘플링
    for (defect, part), group in tl.groupby(["defect_name", "part_name"]):
        n       = min(N_TRAIN_SAMPLES, len(group))
        sampled = group.sample(n=n, random_state=SEED)
        for _, row in sampled.iterrows():
            manifest.append(build_manifest_item(row, split="TL"))
        stats.append({
            "defect_name": defect,
            "part_name":   part,
            "split":       "TL",
            "sampled":     n,
            "total":       len(group),
        })

    # VL 샘플링
    for (defect, part), group in vl.groupby(["defect_name", "part_name"]):
        n       = min(N_VAL_SAMPLES, len(group))
        sampled = group.sample(n=n, random_state=SEED)
        for _, row in sampled.iterrows():
            manifest.append(build_manifest_item(row, split="VL"))
        stats.append({
            "defect_name": defect,
            "part_name":   part,
            "split":       "VL",
            "sampled":     n,
            "total":       len(group),
        })
        
    existing = []
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            existing = json.load(f)
        existing = [
            s for s in existing
            if not (
                s["defect_name"] == "균열" and
                s["part_name"]   == "도장"
            )
        ]
    manifest = existing + manifest
    # 저장
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    # 요약 출력
    print(f"\n✅ 저장 완료: {MANIFEST_PATH}")
    print(f"총 샘플 수: {len(manifest):,}개")
    print()

    stats_df = pd.DataFrame(stats)
    tl_stats = stats_df[stats_df["split"] == "TL"]
    vl_stats = stats_df[stats_df["split"] == "VL"]

    print("=== TL 클래스별 샘플 수 ===")
    print(tl_stats[["defect_name", "part_name", "sampled", "total"]].to_string(index=False))

    print("\n=== VL 클래스별 샘플 수 ===")
    print(vl_stats[["defect_name", "part_name", "sampled", "total"]].to_string(index=False))

    under = stats_df[stats_df["sampled"] < stats_df["total"].apply(
        lambda x: N_TRAIN_SAMPLES if x > N_VAL_SAMPLES else N_VAL_SAMPLES
    )]
    if len(under) > 0:
        print(f"\n⚠️  목표 샘플 미달 클래스: {len(under)}개")
        print(under.to_string(index=False))
    else:
        print(f"\n✅ 모든 클래스 목표 샘플 수 달성")


if __name__ == "__main__":
    main()
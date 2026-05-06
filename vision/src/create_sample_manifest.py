
import json
import pandas as pd
from pathlib import Path

# ── 경로 설정 ──────────────────────────────────────────────
CSV_PATH    = Path.home() / "Desktop/Final_PJ/siren-api/vision/data/dataset_index.csv"
OUTPUT_DIR  = Path.home() / "Desktop/Final_PJ/siren-api/vision/data"
MANIFEST_PATH = OUTPUT_DIR / "sample_manifest.json"

# ── TS_* 파일키 매핑 ───────────────────────────────────────
TS_KEY_MAP = {
    "TL_용접_용접불량_조인트":        "526030",
    "TL_용접_용접블루홀_조인트":       "526031",
    "TL_용접_용접양품_조인트":         "526032",
    "TL_절단_절단불량_모재":           "526033",
    "TL_절단_절단불량_보온재":         "526034",
    "TL_절단_절단양품_모재":           "526035",
    "TL_절단_절단양품_보온재":         "526036",
    "TL_케이블_바인딩불량_케이블타이":  "526037",
    "TL_케이블_바인딩양품_케이블타이":  "526038",
    "TL_케이블_케이블설치불량_케이블그랜드": "526039",
    "TL_케이블_케이블설치양품_케이블그랜드": "526040",
    "TL_케이블_케이블손상_케이블":      "526041",
    "TL_케이블_케이블양품_케이블":      "526042",
    "TL_파이프_볼트체결불량_파이프":    "526043",
    "TL_파이프_볼트체결양품_파이프":    "526044",
    "TL_폼스프레이_폼스프레이불량_우레탄폼": "526045",
    "TL_폼스프레이_폼스프레이양품_우레탄폼": "526046",
    "TL_표면처리_균열_도장":           "526047",
    "TL_표면처리_균열_보온재":         "526048",
    "TL_표면처리_도막떨어짐_도장":     "526049",
    "TL_표면처리_도막분리_도장":       "526050",
    "TL_표면처리_도장흐름_도장":       "526051",
    "TL_표면처리_보온재손상_보온재":    "526052",
    "TL_표면처리_스크래치_도장":       "526053",
    "TL_표면처리_스크래치_모재":       "526054",
    "TL_표면처리_스크래치_보온재":     "526055",
    "TL_표면처리_탱크클리닝불량_모재":  "526056",
    "TL_표면처리_표면양품_도장":       "526057",
    "TL_표면처리_표면양품_모재":       "526058",
    "TL_표면처리_표면양품_보온재":     "526059",
}

# ── 도메인-부품 유효성 검증 ────────────────────────────────
VALID_COMBOS = {
    '용접':      ['조인트'],
    '절단':      ['모재', '보온재'],
    '케이블':    ['케이블타이', '케이블그랜드', '케이블'],
    '파이프':    ['파이프'],
    '폼스프레이': ['우레탄폼'],
    '표면처리':  ['도장', '모재', '보온재'],
}

VALID_DEFECTS = {
    '용접':      ['용접불량', '용접블로우홀', '용접양품'],
    '절단':      ['절단불량', '절단양품'],
    '케이블':    ['바인딩불량', '바인딩양품', '케이블설치불량',
                  '케이블설치양품', '케이블손상', '케이블양품'],
    '파이프':    ['볼트체결불량', '볼트체결양품'],
    '폼스프레이': ['폼스프레이불량', '폼스프레이양품'],
    '표면처리':  ['균열', '도막떨어짐', '도막분리', '도장흐름',
                  '보온재손상', '스크래치', '탱크클리닝불량', '표면양품'],
}

SEED       = 42
N_SAMPLES  = 500

def get_ts_key(zip_source: str) -> str:
    """TL_*.zip → TS_* 파일키 반환"""
    ts_name = zip_source.replace(".zip", "")
    return TS_KEY_MAP.get(ts_name, "")

def main():
    # 1. CSV 로드
    df = pd.read_csv(CSV_PATH)
    print(f"전체 데이터: {len(df):,}개")

    # 2. 정제 (도메인-부품 불일치 제거)
    df_clean = df[
        df.apply(lambda x:
            x['defect_name'] in VALID_DEFECTS.get(x['domain'], []) and
            x['part_name']   in VALID_COMBOS.get(x['domain'], []),
            axis=1
        )
    ]
    print(f"정제 후:   {len(df_clean):,}개")

    # 3. TL만 사용 (VL은 검증용)
    tl = df_clean[df_clean['split'] == 'TL']

    # 4. 클래스별 500장 랜덤 샘플링
    manifest = []
    stats = []

    for (domain, defect, part), group in tl.groupby(
        ['domain', 'defect_name', 'part_name']
    ):
        n = min(N_SAMPLES, len(group))
        sampled = group.sample(n=n, random_state=SEED)

        for _, row in sampled.iterrows():
            manifest.append({
                "file_name":    row['file_name'],
                "zip_source":   row['zip_source'],
                "ts_key":       get_ts_key(row['zip_source']),
                "domain":       domain,
                "defect_name":  defect,
                "part_name":    part,
                "category_id":  int(row['category_id']),
                "label_type":   row['label_type'],
                "split":        "TL",
                "difficulty_score": None,
                "sample_type":  None,
                "input_size":   640,
            })

        stats.append({
            "domain":      domain,
            "defect_name": defect,
            "part_name":   part,
            "sampled":     n,
            "total":       len(group),
        })

    # 5. 저장
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    # 6. 요약 출력
    print(f"\n✅ 저장 완료: {MANIFEST_PATH}")
    print(f"총 샘플 수: {len(manifest):,}개")
    print()
    print("=== 클래스별 샘플 수 ===")
    stats_df = pd.DataFrame(stats)
    print(stats_df.to_string(index=False))

    # 500장 미만 클래스 확인
    under_500 = stats_df[stats_df['sampled'] < N_SAMPLES]
    if len(under_500) > 0:
        print(f"\n⚠️  500장 미만 클래스:")
        print(under_500.to_string(index=False))
    else:
        print(f"\n✅ 모든 클래스 {N_SAMPLES}장 확보")

if __name__ == "__main__":
    main()
"""
analyze_labels.py — 로컬 실행
라벨 포맷 분석 후 마이그레이션 전략 결정용
"""

import json
from pathlib import Path
from collections import Counter

LABEL_ROOT = Path("/Users/seolhakim/Desktop/Final_PJ/siren-api/vision/data/labels/TL/02.라벨링데이터/TL_표면처리_도막떨어짐_도장")  # ← 수정


def analyze():
    all_files = list(LABEL_ROOT.rglob("*.*"))
    
    # 1. 확장자 분포
    ext_counter = Counter(f.suffix.lower() for f in all_files if f.is_file())
    print("=== 확장자 분포 ===")
    for ext, count in ext_counter.most_common():
        print(f"  {ext:<10} {count}")

    # 2. 전체 용량
    total_bytes = sum(f.stat().st_size for f in all_files if f.is_file())
    print(f"\n=== 전체 용량 ===")
    print(f"  {total_bytes / (1024**3):.2f} GB  ({len(all_files)}개 파일)")

    # 3. 샘플 내용 확인
    print("\n=== 샘플 파일 내용 ===")
    for ext in ext_counter:
        sample = next((f for f in all_files if f.suffix.lower() == ext), None)
        if not sample:
            continue
        print(f"\n[ {ext} ] {sample.name}")
        try:
            content = sample.read_text(encoding="utf-8")
            if ext == ".json":
                data = json.loads(content)
                # 최상위 키만 출력
                print(f"  최상위 키: {list(data.keys())[:10]}")
                # image 경로 포함 여부 확인
                content_str = json.dumps(data)
                for keyword in ("file_name", "image_path", "filename", "path"):
                    if keyword in content_str:
                        print(f"  경로 키 발견: '{keyword}'")
            else:
                print(f"  {content[:200]}")
        except Exception as e:
            print(f"  읽기 실패: {e}")

    # 4. 폴더 구조 depth
    depths = [len(f.relative_to(LABEL_ROOT).parts) for f in all_files if f.is_file()]
    if depths:
        print(f"\n=== 디렉토리 depth ===")
        print(f"  mean: {sum(depths)/len(depths):.1f}")
        print(f"  max : {max(depths)}")


if __name__ == "__main__":
    analyze()
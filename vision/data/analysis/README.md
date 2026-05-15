# vision/data/analysis

> **Generated artifact directory — manual edit 금지.**
> 이 디렉터리의 파일은 파이프라인이 자동 생성한 산출물이다.
> 직접 수정하지 않는다. 파이프라인을 재실행하면 언제든 재생성할 수 있다.

## 재생성 방법

```python
from vision import (
    build_ontology_table,
    build_image_split_records,
    build_sampling_manifest,
    load_data_config,
    load_dataset_index_rows,
    normalize_rows,
)

data_config = load_data_config()
rows = load_dataset_index_rows(data_config.dataset_index_path)
normalized_rows = normalize_rows(rows, slugs_path=data_config.ontology_slugs_path)
ontology_records = build_ontology_table(normalized_rows)
split_records, _ = build_image_split_records(normalized_rows, ontology_records=ontology_records)
build_sampling_manifest(split_records, ontology_records)
```

## 파일 목록

| 파일 | 역할 |
|------|------|
| `ontology_audit.csv` | canonical class별 label_type·taxonomy_status·이미지 수 집계 원본 |
| `ontology_audit.md` | `ontology_audit.csv`의 Markdown 요약 보고서 |
| `quality_state_audit.csv` | quality_state 규칙 적용 결과 — normal/defect/review 분포 집계 |
| `sampling_audit.csv` | class-balanced train sampling 결과 — 선택 이미지 수·비율 집계 원본 |
| `sampling_audit.md` | `sampling_audit.csv`의 Markdown 요약 보고서 |
| `split_audit.csv` | TS/VS split 충돌 해결 결과 — train/val 배정 이미지 수 집계 원본 |
| `split_audit.md` | `split_audit.csv`의 Markdown 요약 보고서 |

## 원칙

- 이 파일들은 현재 파이프라인 상태의 스냅샷이다.
- 파이프라인 설정(`vision/configs/`)이나 온톨로지(`ontology_slugs.yaml`)가 바뀌면 재생성해야 한다.
- 분석 결과를 참조할 때는 파일을 직접 편집하지 말고 파이프라인을 다시 실행한다.

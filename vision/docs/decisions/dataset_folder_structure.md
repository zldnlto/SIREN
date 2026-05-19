# Dataset Folder Structure 결정 문서

> 기준 문서: ontology-expert 검증 결과 (2026-05-19)
> migrate.py 변경 사항의 근거 및 마이그레이션 검증 체크리스트로 사용

---

## 최종 폴더 구조

```
images/
├── surface_treatment/
│   ├── crack_paint/
│   ├── coating_drop_paint/
│   ├── coating_separation_paint/
│   ├── paint_run_paint/
│   ├── insulation_damage_insulation/
│   ├── scratch_paint/
│   ├── scratch_base_material/
│   ├── scratch_insulation/
│   ├── tank_cleaning_defect_base_material/
│   └── background/
│
├── welding/
│   ├── weld_defect_joint/
│   ├── weld_blowhole_joint/
│   └── background/
│
├── cutting/
│   ├── cut_defect_base_material/
│   ├── cut_defect_insulation/
│   └── background/
│
├── cable/
│   ├── binding_defect_cable_tie/
│   ├── cable_install_defect_cable_gland/
│   ├── cable_damage_cable/
│   └── background/
│
├── pipe/
│   ├── bolt_defect_pipe/
│   └── background/
│
└── foam_spray/
    ├── foam_spray_defect_urethane_foam/
    └── background/

manifests/
├── train.txt   ← TS_ 출처 이미지 절대 경로 목록
└── val.txt     ← VS_ 출처 이미지 절대 경로 목록
```

---

## canonical_class_name 규칙

`canonical_class_name = defect_slug_part_slug`

ontology-expert slug 테이블 기준. `category_id` 또는 임의 명칭 사용 금지.

### 결함 클래스 전체 목록

| 한글 (resized/ 폴더명) | canonical_class_name |
|---|---|
| 균열_도장 | `crack_paint` |
| 도막떨어짐_도장 | `coating_drop_paint` |
| 도막분리_도장 | `coating_separation_paint` |
| 도장흐름_도장 | `paint_run_paint` |
| 보온재손상_보온재 | `insulation_damage_insulation` |
| 스크래치_도장 | `scratch_paint` |
| 스크래치_모재 | `scratch_base_material` |
| 스크래치_보온재 | `scratch_insulation` |
| 탱크클리닝불량_모재 | `tank_cleaning_defect_base_material` |
| 용접불량_조인트 | `weld_defect_joint` |
| 용접블로우홀_조인트 | `weld_blowhole_joint` |
| 절단불량_모재 | `cut_defect_base_material` |
| 절단불량_보온재 | `cut_defect_insulation` |
| 바인딩불량_케이블타이 | `binding_defect_cable_tie` |
| 케이블설치불량_케이블그랜드 | `cable_install_defect_cable_gland` |
| 케이블손상_케이블 | `cable_damage_cable` |
| 볼트체결불량_파이프 | `bolt_defect_pipe` |
| 폼스프레이불량_우레탄폼 | `foam_spray_defect_urethane_foam` |

---

## domain slug 결정

| 한글 | slug | 비고 |
|---|---|---|
| 표면처리 | `surface_treatment` | `surface` 사용 금지 |
| 용접 | `welding` | |
| 절단 | `cutting` | |
| 케이블 | `cable` | |
| 파이프 | `pipe` | |
| 폼스프레이 | `foam_spray` | `foam` 사용 금지 |

---

## background 폴더 설계 결정

**결정:** 도메인별 양품 이미지를 `<domain>/background/`로 통합

**근거:**
- Training Layer(Layer 3) 결정 — YOLO detection 학습에서 hard negative sample로 투입
- 양품 종류별 구분(도장/모재/보온재 등)은 학습 목적상 불필요
- Layer 2 원본 annotation 정보는 `labels/` 및 metadata에 보존됨

**주의:** migrate.py에서 background로 매핑하는 것은 Layer 3 설계 결정이다.
Layer 2 정보 소실이 아니라 export 정책의 의도적 단순화.

---

## train/val 분리 방식

- `images/<domain>/<class>/` 안에 train/val 이미지가 **혼재**
- 분리 기준은 오직 manifest 파일
  - `TS_*` 출처 → `manifests/train.txt`
  - `VS_*` 출처 → `manifests/val.txt`
- val 이미지는 augmentation 없이 원본만 사용

---

## UNMAPPED 처리

`resized/` 안의 아래 폴더는 migration 대상에서 제외:

| 폴더 | 이유 |
|---|---|
| `likely_label_error/` | 라벨 오류 의심 (폼불량_폼, 폼불량_우레탄) |
| `taxonomy_extension_candidate/` | 온톨로지 미확정 (폼손상_폼) |

→ `taxonomy_status`가 `valid_taxonomy`가 아닌 경우 학습 export 제외 (삭제 금지)

---

## migrate.py 검증 체크리스트

마이그레이션 실행 후 확인 항목:

- [ ] `unmapped = 0` (UNMAPPED 폴더 제외 시)
- [ ] `images/surface_treatment/`, `images/foam_spray/` 존재 (`surface/`, `foam/` 없음)
- [ ] `manifests/train.txt` + `manifests/val.txt` 둘 다 존재
- [ ] `val.txt` 줄 수 > 0
- [ ] 각 도메인 background/ 폴더 존재
- [ ] `images/train/`, `images/val/` 폴더 없음 (이전 구조 잔재)

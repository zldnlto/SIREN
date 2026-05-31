# vision-colab.md — Colab 세션 운영 가이드

vision-runner 에이전트 및 Colab 노트북 작업 시 반드시 참조한다.
노트북 코드를 작성하거나 수정하기 전에 이 문서의 API 계약과 Gotcha를 먼저 확인한다.

---

## Drive 디렉터리 맵 (확정)

```
/content/drive/MyDrive/
├── siren_repo/
│   └── data/
│       ├── sampled_surface.zip          # 표면처리 이미지 7,639개 (flat JPG)
│       └── analysis/
│           └── dataset_index.csv        # 전체 annotation index
└── siren/
    ├── data/
    │   ├── labels/                      # 도메인별 개별 zip (TL_*.zip, VL_*.zip)
    │   │   ├── TL_표면처리_*.zip
    │   │   └── ...
    │   ├── labels_flat/                 # flatten된 JSON 라벨 (Drive 영구 보관)
    │   └── processed/                   # pickle 체크포인트 (Drive 영구 보관)
    │       ├── normalized_rows.pkl      # Cell 3
    │       ├── surface_ontology.pkl     # Cell 4
    │       ├── split_manifest.pkl       # Cell 5 (random_state=42)
    │       ├── surface_rows.pkl         # Cell 6 필터링 결과
    │       └── sampling_manifest.json   # Cell 5 샘플링 결과
    └── runs/                            # YOLO 학습 결과 Drive 미러
        └── siren-seg-v1/
            └── weights/
                ├── best.pt
                └── last.pt             # resume 재개 기준
```

**세션 휘발 경로 (`/content`):**
- `/content/sampled_images/` — SAMPLED_ZIP 추출 결과 (매 세션 재추출)
- `/content/siren/vision/data/curated_local/` — export 결과 (매 세션 재export)

**Drive 영구 경로 (세션 재시작 후 재사용):**
- `siren/data/labels_flat/` — 라벨 flatten 결과, 재추출 불필요
- `siren/data/processed/` — pickle 체크포인트 전체 (Drive 이전 완료)
  - `normalized_rows.pkl` — Cell 3 결과
  - `surface_ontology.pkl` — Cell 4 결과
  - `split_manifest.pkl` — Cell 5 결과 (random_state=42 고정)
  - `surface_rows.pkl` — Cell 6 필터링 결과
  - `sampling_manifest.json` — Cell 5 샘플링 결과
- `siren/runs/` — 학습 가중치 미러 (best.pt, last.pt)

---

## 핵심 API 계약

### export_segmentation_dataset

```python
result = export_segmentation_dataset(rows, ontology_records, resized_root, labels_root, output_root)
# 올바른 접근
result.report.exported_images   # ✅
result.report.blocked_images
result.report.skipped_images
# 잘못된 접근
result.exported_count           # ❌ AttributeError
```

### build_segmentation_runtime_config

```python
runtime = build_segmentation_runtime_config(surface_ontology)
# 내부에서 exception 발생 시 DEFAULT_CLASS_NAMES로 silent fallback됨
# 반드시 아래 assert 추가
from vision.src.constants import DEFAULT_CLASS_NAMES
assert runtime.class_names != DEFAULT_CLASS_NAMES, \
    "fallback 발생 — surface_ontology의 allowed_task_types 확인"
assert len(runtime.class_names) > 0
```

### VisionRuntimeConfig (frozen dataclass)

```python
# frozen이라 직접 수정 불가 → dataclasses.replace 사용
from dataclasses import replace
_paths = replace(runtime.paths, resized_root=CURATED_ROOT, drive_runs_root=DRIVE_RUNS)
runtime = replace(runtime, paths=_paths, device="cuda")
```

### train_yolo_segmentation

```python
result = train_yolo_segmentation(
    runtime=runtime,
    run_name=RUN_NAME,
    curated_root=CURATED_ROOT,
    ontology_records=surface_ontology,
)
result.best_weight_path          # Path (never None, 없으면 FileNotFoundError)
result.drive_best_weight_path    # Path | None
result.artifacts.local_run_dir   # Path
```

### build_image_split_records / build_sampling_manifest

```python
records, leak_findings = build_image_split_records(normalized, config=sampling_cfg)
# 반환값이 tuple[list, tuple] — 언패킹 필수

# random_state 지원 여부 불확실 → try/except로 탐지
RANDOM_STATE = 42  # 재현성 고정 상수 — 변경 시 split_manifest.pkl 삭제 후 재실행
try:
    split_records, leaks = build_image_split_records(..., random_state=RANDOM_STATE)
except TypeError:
    split_records, leaks = build_image_split_records(...)  # 미지원 시 annotation split 필드 사용
```

### Cell 8 — YOLO 학습 재개 (resume)

```python
# last.pt 존재 시 자동 재개
_last_pt = artifacts.local_weights_dir / "last.pt"
if _last_pt.exists():
    from ultralytics import YOLO as _YOLO
    _model = _YOLO(str(_last_pt))
    _train_raw = _model.train(resume=True)
    # TrainingRunResult 수동 구성
    train_result = TrainingRunResult(
        artifacts=artifacts,
        train_result=_train_raw,
        best_weight_path=artifacts.best_weight_path,
        drive_best_weight_path=sync_best_weight_to_drive(artifacts, artifacts.best_weight_path),
    )
else:
    train_result = train_yolo_segmentation(...)
# last.pt는 Drive runs/ 에 미러되므로 세션 재시작 후 resume 가능
```

### YOLO results.csv mAP 컬럼

```python
# 컬럼명에 앞뒤 공백 붙는 경우 있음 → strip 필수
_last = {k.strip(): v.strip() for k, v in rows[-1].items()}
_map50 = _last.get("metrics/mAP50(M)", _last.get("metrics/mAP50(B)", "N/A"))
# segmentation: (M) = mask mAP  /  (B) = bbox mAP
# 세그멘테이션 모델 평가 시 (M) 우선
```

---

## 알려진 Gotcha

### 1. normalized rows 필터링 2단계 필수

`normalized`는 전체 도메인 포함. 표면처리 export 시 반드시 두 조건 모두 적용:

```python
_sampled_fnames = {f.name for f in SAMPLED_IMAGES_DIR.rglob("*") if f.is_file()}
_surface_rows = [
    r for r in normalized
    if r.annotation_domain == TARGET_DOMAIN      # 도메인 필터
    and r.file_name in _sampled_fnames           # 실제 존재하는 이미지만
]
```

`_sampled_fnames` 없이 도메인 필터만 하면 Drive에 없는 파일명이 포함되어
`export_result.report.blocked_images`가 폭증한다.

### 2. LABELS_ZIP 단일 파일 없음

`/siren/data/labels.zip` 단일 파일은 존재하지 않는다.
실제 구조는 `/siren/data/labels/` 하위 도메인별 개별 zip.
labels_flat은 flatten 스크립트로 Drive에 사전 생성 후 재사용한다.

### 3. CURATED_ROOT 한국어 디렉터리

export 오류 시 한국어 이름 디렉터리가 생성될 수 있다.
세션 시작 시 또는 export 전에 정리:

```python
_korean_dirs = [d for d in CURATED_ROOT.iterdir()
                if d.is_dir() and any(ord(c) > 127 for c in d.name)]
for d in _korean_dirs:
    shutil.rmtree(d)
```

### 4. SKIP_EXPORT 조건 — 강화된 체크 필수

```python
# 약한 체크 (디렉터리 존재만) → 비어있어도 스킵
SKIP_EXPORT = CURATED_ROOT.exists()  # ❌

# 강화된 체크 — train/val 모두 있는 클래스가 expected와 일치하는지
_complete_classes = {
    d.name for d in CURATED_ROOT.iterdir()
    if d.is_dir()
    and all(ord(c) <= 127 for c in d.name)
    and (d / "images" / "train").exists()
    and (d / "images" / "val").exists()
}
SKIP_EXPORT = bool(_expected_classes) and _expected_classes.issubset(_complete_classes)  # ✅
```

### 5. mAP 지표 혼동

- `metrics/mAP50(B)` = bounding box mAP → detection 모델
- `metrics/mAP50(M)` = mask mAP → **segmentation 모델 (이것을 봐야 함)**

### 6. VisionPaths.drive_runs_root 필드명

`drive_runs_root`가 필드이고 `drive_run_dir(run_name)`은 메서드.
`replace(runtime.paths, drive_runs_root=DRIVE_RUNS)` 로 override.

---

## 세션 시작 체크리스트

```
[ ] Cell 1: Drive 마운트 + git pull + pip install
[ ] Cell 2: 경로 assert 모두 통과 (SAMPLED_ZIP, LABELS_FLAT_DIR, PROCESSED_DIR=Drive)
[ ] Cell 3: normalized 로드 — Drive pkl 있으면 즉시 로드, 없으면 CSV 파싱 후 Drive 저장
[ ] Cell 4: surface_ontology 로드 — Drive pkl 있으면 즉시 로드, canonical_class_name 영문 확인
[ ] Cell 5: split manifest 로드 — Drive pkl 있으면 즉시 로드, 없으면 random_state=42로 생성
[ ] (선택) 미니 smoke test: 20개 샘플 export → exported > 0 확인 후 Cell 6 전체 실행
[ ] Cell 6: export 완료 후 _stats 클래스별 train/val 수 확인
[ ] Cell 7: runtime.class_names != DEFAULT_CLASS_NAMES assert 통과
[ ] Cell 8: last.pt 있으면 resume, 없으면 신규 학습
```

**Drive pkl 초기화가 필요한 경우** (코드·데이터 변경 시):
```
- normalized 재생성: CKPT_NORMALIZED 삭제
- ontology 재생성 : CKPT_ONTOLOGY 삭제
- split 재생성   : CKPT_MANIFEST + CKPT_SURFACE_ROWS 삭제
- 전체 초기화    : processed/ 디렉터리 전체 삭제
```

---

## 미니 Smoke Test (Cell 6 전에 실행)

전체 실행 전 export 파이프라인 동작 확인용. `exported > 0` 이면 Cell 6 진행.

```python
from vision.src.data import export_segmentation_dataset
import tempfile, random
from pathlib import Path

_smoke_rows = random.sample(_surface_rows, min(20, len(_surface_rows)))
with tempfile.TemporaryDirectory() as _tmp:
    _smoke_result = export_segmentation_dataset(
        _smoke_rows,
        ontology_records=surface_ontology,
        resized_root=SAMPLED_IMAGES_DIR,
        labels_root=LABELS_FLAT_DIR,
        output_root=Path(_tmp),
    )
_r = _smoke_result.report
print(f"smoke: exported={_r.exported_images}  blocked={_r.blocked_images}  skipped={_r.skipped_images}")
assert _r.exported_images > 0, "smoke test 실패 — labels_flat / surface_rows 매칭 확인 필요"
print("✅ smoke test 통과")
```

---

## 학습 전략 메모

### Phase 1 — 베이스라인
표면처리 전체 데이터로 첫 학습. `sampled_surface.zip` 기준.

### Phase 2 이후 — Self-paced (확정)
- inference confidence 기준으로 easy / hard 분류
- easy 샘플: **제거 아님**, 해상도 낮춰서(blur/noise/brightness/resize) 유지 → 파일 부하 감소
- 확보된 용량에 hard 샘플 추가
- 반복

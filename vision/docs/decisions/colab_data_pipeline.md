# Colab 데이터 파이프라인 — 경로·샘플링·파일 사용 결정 문서

> 기준: 2026-05-26 세션 작업 결과
> 기존 split_sampling_report.md는 알고리즘 설계 기준이고,
> 이 문서는 Colab 실행 환경에서 실제로 어떤 경로를 어떻게 쓰는지를 다룬다.

---

## 1. Google Drive 경로 구조

```
MyDrive/
├── siren_repo/
│   └── data/
│       ├── analysis/
│       │   └── dataset_index.csv        ← 전체 annotation 인덱스 (299,123행, 279,320 unique 이미지)
│       └── sampled_surface.zip          ← Colab 실험용 샘플 이미지 백업 (표면처리 도메인, 이미지만)
│
└── siren/
    └── data/
        └── images/                      ← 원본 이미지 (261,191개, find 기준)
            └── (도메인별 하위 폴더)
```

### 주의사항

- `siren/data/images/` 아래에는 **표면처리 도메인 이미지만** 실제로 존재하는 것으로 추정
- 용접·절단·케이블·파이프·폼스프레이 도메인 이미지는 **별도 Drive 경로**에 있거나 아직 업로드 안 된 상태
- 근거: 전 도메인 샘플링(18,817개) 시 1,507개 누락, 표면처리만(8,661개) 샘플링 시 누락 0

---

## 2. Colab 로컬 경로 구조 (실행 중 생성)

```
/content/
├── siren/                               ← git clone 위치 (REPO_PATH = "/content/siren")
│   └── vision/
│       └── data → [symlink]            ← Cell 1에서 MyDrive/siren_repo/data 로 symlink 생성
├── sampled_images/                      ← sampled_surface.zip 추출 위치 (flat, 파일명만)
├── labels_flat/                         ← labels.zip 추출 위치 (AIHub JSON 어노테이션)
└── exports/                             ← export_segmentation_dataset() 출력
    └── segmentation/
        ├── train/
        │   ├── images/
        │   └── labels/                  ← YOLO .txt 형식
        └── val/
            ├── images/
            └── labels/
```

### symlink 연결 방식

`vision_data_paths.yaml`의 상대 경로(`vision/data/analysis/dataset_index.csv`)와
실제 Drive 파일(`MyDrive/siren_repo/data/analysis/dataset_index.csv`)을
**Cell 1의 symlink**로 연결한다.

```python
os.symlink(
    "/content/drive/MyDrive/siren_repo/data",
    "/content/siren/vision/data"
)
# 검증 (올바른 경로)
print(Path("/content/siren/vision/data/analysis/dataset_index.csv").exists())
```

> **주의**: `Path("/content/siren/vision/data/dataset_index.csv").exists()` 는 틀린 경로.
> `analysis/` 하위에 있으므로 반드시 `analysis/` 를 포함해야 한다.

---

## 3. 파일별 역할 정리

| 파일 | 위치 | 역할 | 비고 |
|------|------|------|------|
| `dataset_index.csv` | Drive `siren_repo/data/analysis/` | 전체 annotation 메타데이터 | split, domain, defect_name, part_name, label_type 포함 |
| `sampled_surface.zip` | Drive `siren_repo/data/` | 표면처리 샘플 이미지 백업 | 이미지만 있음, 라벨 없음. 재실행 시 Drive FUSE 재접근 방지용 |
| `labels.zip` | Drive (경로 미확인) | AIHub JSON 어노테이션 원본 | YOLO .txt 변환의 소스 |
| `sampling.yaml` | `vision/configs/` | 정식 학습용 샘플링 캡 설정 | regular 5000, tail 1000 |
| `sampling_colab.yaml` | `vision/configs/` | Colab 실험용 샘플링 캡 설정 | regular 500, tail 100 (T4 단일 세션 목표) |
| `split_sampling_report.md` | `vision/docs/decisions/` | 샘플링 알고리즘 결정 기록 | selected train 136,426 / val 31,037 |

---

## 4. 샘플링 전략

### 정식 전략 (`sampling.yaml`)

```yaml
train_caps:
  regular: 5000   # unique images >= 1000인 클래스
  tail: 1000      # unique images 100~999인 클래스
  review: 0       # taxonomy_review 후보 제외
validation_policy: natural  # val은 전체 사용
```

→ 예상 결과: train 136,426장 / val 31,037장 (split_sampling_report.md 기준)

### Colab 실험용 전략 (`sampling_colab.yaml`)

```yaml
train_caps:
  regular: 500   # T4 단일 세션 상한
  tail: 100
  review: 0
validation_policy: natural
```

- 대상: 표면처리 도메인 (베이스라인)
- Cell 5에서 `sampling.yaml` 대신 `sampling_colab.yaml` 을 명시적으로 로드해야 한다

> **결정**: "표면처리만 쓰면 어차피 5000에 안 닿으니 괜찮다"는 암묵적 가정을 사용하지 않는다.
> `sampling_colab.yaml`로 cap을 명시해 full-domain 확장 시 의도치 않은 규모 증가를 방지한다.

### 양품 클래스 처리 (ADR-001)

- 양품 이미지는 샘플에 **포함** (이미지 파일로 투입)
- YOLO class ID는 **부여하지 않음** (bbox 어노테이션 없음)
- `export_segmentation_dataset()`이 빈 label 파일로 처리 → hard negative 역할

---

## 5. 누락 파일 원인 분석

### 현상

```
전 도메인 샘플링: 18,817개 중 1,507개 (8%) 누락
표면처리만 샘플링: 8,661개 중 0개 누락
```

### 원인 확정

| 도메인 | 원인 | 근거 |
|---|---|---|
| 용접 (718개) | Drive `siren/data/images/` 에 용접 이미지 없음 | 별도 경로 또는 미업로드 |
| 표면처리 균열_보온재 등 (1,411개) | Drive FUSE `find` 불완전 열거 | 표면처리만 샘플링 시 동일 파일 누락 0 확인됨 — 261K 파일 열거 중 캐시 미스로 서브디렉터리 일부 누락 추정 |

### 조치 방향

- **베이스라인**: 표면처리 도메인만으로 진행 (누락 0 검증됨, 8,661장)
- **중기**: 용접 등 나머지 도메인 이미지의 실제 Drive 경로 확인 후 `SOURCE_DIR` 목록 확장
- **표면처리 내 보온재 누락**: 표면처리만 재샘플링 시 해소 예상 (FUSE 재열거)

---

## 6. 파이프라인 실행 순서 (Colab)

```
Cell 1: 환경 설정
        - ultralytics 설치, Drive 마운트
        - git clone → /content/siren
        - symlink: /content/siren/vision/data → MyDrive/siren_repo/data
        - 검증: Path("/content/siren/vision/data/analysis/dataset_index.csv").exists()

Cell 2: sys.path + 경로 초기화
        - REPO_PATH = "/content/siren"
        - load_data_config() + build_default_paths()
        ※ Cell 2의 DRIVE_DATA/DRIVE_CONFIGS 검증 블록은 symlink 이후 불필요 — 제거 권장

Cell 3: 데이터 로드 및 정규화
        - load_dataset_index + normalize_rows
        - annotation_domain은 한국어 원문 유지

Cell 4: 도메인 필터 + 온톨로지 테이블 생성
        - TARGET_DOMAIN = "표면처리"로 필터
        - build_ontology_table은 반드시 surface_rows 기준 (전체 rows 기준 금지)

Cell 5: Train/Val 분할 + 샘플링 매니페스트
        - sampling_config_path = paths.vision_root / "configs" / "sampling_colab.yaml"  ← Colab용
        - build_image_split_records → build_sampling_manifest → save_*

Cell 6a: 압축 해제
         - sampled_surface.zip → /content/sampled_images/  (flat 구조)
         - labels.zip          → /content/labels_flat/

Cell 6:  export 파이프라인 실행
         - export_segmentation_dataset(resized_root=/content/sampled_images/, ...)
         ※ labels 경로는 /content/labels_flat/ 기준으로 확인 필요

Cell 7:  검증
         - 클래스별 이미지/라벨 수 일치 확인
         - 양품 클래스의 label 파일이 빈 파일인지 확인

Cell 8:  학습
         - train_yolo_segmentation(runtime, run_name="siren-seg-v1", ...)
         ※ build_segmentation_runtime_config() 사용 (build_default_runtime_config() 금지)
```

---

## 8. 실행 결과 및 전략 결정 (2026-05-26)

### Cell 6 export 결과

```
샘플링 선택 파일 : 83,453
export 대상      : 90,666
exported         : 2,644
blocked          : 52,958
skip             : 27,867

[train] images=2,058  labels=2,058  ✓
[val]   images=585    labels=585    ✓
양품 hard negative   : 0개
```

### blocked 원인 확정

```
LOCAL_IMAGES 보유: 7,639
sampling 선택:    83,453
실제 매칭:         3,831 (5%)
이미지 없음:      79,622
```

`sampled_surface.zip`이 현재 sampling manifest와 **다른 기준으로 만들어진 파일**이었음.
zip은 이전 세션의 샘플링 결과물이고, 현재 `build_sampling_manifest()`가 선택한 파일과 5%만 겹침.

### 양품 hard negative 없는 이유

sampling_records에 양품 rows가 포함되지 않았거나 export 시 skip된 것으로 추정.
→ 중기 재학습 시 확인 및 보완 필요.

### 전략 결정: 베이스라인 smoke test → 프로덕트 연결 → 데이터 보충

**Phase 1 (현재)**: 2,644개 모델로 `best.pt` 확보 → FastAPI 추론 엔드포인트 + Flutter 카메라 연결
- 파이프라인 구조(API 응답 계약, 이미지 전처리, 좌표 역변환) 검증이 목적
- 데이터 부족으로 false positive 多 예상, 특히 양품 이미지 입력 시

**Phase 2 (중기)**: Drive 직접 접근으로 full dataset export → 재학습 → 모델 교체
```python
# Cell 6 resized_root를 Drive로 교체
resized_root = Path("/content/drive/MyDrive/siren/data/images/")
```
- 양품 hard negative 포함 여부 재확인
- sampled_surface.zip을 현재 sampling manifest 기준으로 재생성

---

## 7. 핵심 결정 사항

| 결정 | 내용 | 근거 |
|------|------|------|
| vision 파이프라인 우선 | 수동 파일 복사 대신 `export_segmentation_dataset()` 사용 | 라벨 생성이 어차피 필요 |
| symlink 방식 채택 | `vision/data` → Drive `siren_repo/data` symlink | `vision_data_paths.yaml` 상대 경로와 일치, 재시작 시 재생성 필요 |
| `sampled_surface.zip` 백업 보관 | 이미지 캐시로 활용, 파이프라인 재실행 시 Drive FUSE 절감 | 재연결 시 복구 비용 감소 |
| `build_segmentation_runtime_config()` 강제 | class_names가 label map에서 자동 결정 | CONTEXT.md 및 COLAB_GUIDELINE 명시 |
| `sampling_colab.yaml` 분리 | Colab 실험용 cap(500/100)을 별도 파일로 명시 | 암묵적 "어차피 안 닿는다" 가정 제거, full-domain 확장 시 안전 |
| 베이스라인은 표면처리 먼저 | 누락 0 확인, 파이프라인 검증 후 전 도메인 확장 | 누락 원인 확정됨 — 용접 이미지 Drive 미업로드 + 표면처리 FUSE 불완전 열거 (Section 5) |

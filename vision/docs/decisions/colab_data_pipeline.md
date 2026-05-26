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
│       └── sampled_images.zip           ← Colab 실험용 샘플 이미지 백업 (18,817장, 이미지만)
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
├── siren-api/                           ← git clone 위치
├── sampled_images/                      ← sampled_images.zip 추출 위치 (flat, 파일명만)
├── labels/                              ← labels.zip 추출 위치 (AIHub JSON 어노테이션)
└── exports/                             ← export_segmentation_dataset() 출력
    └── segmentation/
        ├── train/
        │   ├── images/
        │   └── labels/                  ← YOLO .txt 형식
        └── val/
            ├── images/
            └── labels/
```

---

## 3. 파일별 역할 정리

| 파일 | 위치 | 역할 | 비고 |
|------|------|------|------|
| `dataset_index.csv` | Drive `siren_repo/data/analysis/` | 전체 annotation 메타데이터 | split, domain, defect_name, part_name, label_type 포함 |
| `sampled_images.zip` | Drive `siren_repo/data/` | 샘플 이미지 백업 | 이미지만 있음, 라벨 없음. 재실행 시 Drive FUSE 재접근 방지용 |
| `labels.zip` | Drive (경로 미확인) | AIHub JSON 어노테이션 원본 | YOLO .txt 변환의 소스 |
| `sampling.yaml` | `vision/configs/` | 샘플링 캡 설정 | 정식: regular 5000, tail 1000 |
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

### Colab 실험용 축소 전략 (2026-05-26 세션)

```python
N_TRAIN = 500   # defect × part 조합당 TL 상한
N_VAL   = 100   # defect × part 조합당 VL 상한
SEED    = 42
```

- 대상: 전 도메인 23클래스 (`df.copy()`, 도메인 필터 없음)
- 결과: **18,817개** (TL 약 15,700 + VL 약 3,100)
- 누락: 1,507개 → 도메인별 Drive 경로 불일치 문제 (아래 5절 참고)

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

### 원인 (추정)

`SOURCE_DIR = /content/drive/MyDrive/siren/data/images/` 아래에
표면처리 도메인 이미지만 있고, 나머지 도메인(용접/절단/케이블/파이프/폼스프레이)은
다른 경로에 있거나 Drive에 업로드되지 않은 상태.

### 실측 결과 (2026-05-26)

전 도메인 샘플링(18,817개) 실행 결과:

```
누락 파일: 2,129개

[도메인별]
표면처리: 1,411개
용접:      718개

[zip_source 상위]
TL_용접_용접양품_조인트.zip       1,017개
TL_표면처리_균열_보온재.zip         699개
VL_표면처리_균열_도장.zip           174개
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
Cell 1-3: 환경 설정 (repo clone, sys.path, Drive mount)
Cell 4:   load_data_config + load_dataset_index_rows
Cell 5:   sampling.yaml 로드 (오타 주의: sampling_config.yaml → sampling.yaml)

Cell 6a:  압축 해제
          - sampled_images.zip → /content/sampled_images/  (flat 구조)
          - labels.zip         → /content/labels/

Cell 6:   export 파이프라인 실행
          normalize_rows → build_sampling_manifest
          → export_segmentation_dataset(resized_root=/content/sampled_images/)
          ※ flat 구조 호환 여부 확인 필요 (원본 폴더 구조 가정 시 Drive FUSE 직접 사용)

Cell 7:   검증
          - 클래스별 이미지/라벨 수 일치 확인
          - 양품 클래스의 label 파일이 빈 파일인지 확인

Cell 8:   학습
          train_yolo_segmentation(runtime, run_name="siren-seg-v1", ...)
          ※ build_segmentation_runtime_config() 사용 (build_default_runtime_config() 금지)
```

---

## 7. 핵심 결정 사항

| 결정 | 내용 | 근거 |
|------|------|------|
| vision 파이프라인 우선 | 수동 파일 복사 대신 `export_segmentation_dataset()` 사용 | 라벨 생성이 어차피 필요 |
| `sampled_images.zip` 백업 보관 | 이미지 캐시로 활용, 파이프라인 재실행 시 Drive FUSE 절감 | 재연결 시 복구 비용 감소 |
| `build_segmentation_runtime_config()` 강제 | class_names가 label map에서 자동 결정 | CONTEXT.md 및 COLAB_GUIDELINE 명시 |
| Colab 실험용 cap | TL 500 / VL 100 per class | T4 GPU 한 세션 내 완료 목표 |
| 베이스라인은 표면처리 먼저 | 누락 0 확인, 파이프라인 검증 후 전 도메인 확장 | 누락 1,507개 원인 미확인 상태 |

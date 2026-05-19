# RAG 조치 카드 설계 결정 문서

> 결정일: 2026-05-19
> 관련 이슈: #99

---

## 1. 심각도(severity) 추후 기능으로 이연

**결정:** MVP에서 severity 제거. `quality_state: defect | good` 2단계만 사용.

**Why:** 모델 베이스라인 실험 전 결함별 위험도 확정 불가. confidence 기반 severity는 도메인 위반. 결함 종류별 고정 severity는 도메인 전문가 자문 필요.

**How to apply:** API 응답에 `severity` 필드 없음. Flutter UI는 QualityBadge(결함있음/정상) 2단계. 베이스라인 confusion matrix 확인 후 severity 재논의.

---

## 2. RAG 조치 카드 사전 생성 + DB 캐싱

**결정:** 런타임에 RAG/OpenAI 호출하지 않는다. 배포 전 18개 클래스 조치 카드를 RAG로 생성하고 `guidance` 테이블에 seed.

**Why:** 조치 카드 내용은 클래스별 고정값. 매 요청마다 동일 결과를 OpenAI에 반복 요청할 이유 없음. API 응답 3초 목표 달성을 위해 런타임 OpenAI 의존성 제거 필요.

**How to apply:** 런타임 조치 카드 조회 = `canonical_class_name` 기준 DB lookup. RAG 파이프라인은 초기 seed 생성 전용 스크립트로 분리. 추후 SOP 문서 갱신 시 seed 재실행.

---

## 3. 결함 없음(good) 화면 별도 분기

**결정:** `quality_state = good`이면 조치 카드 없음. RAG 서버 호출 없음. 별도 화면(Screen 5)으로 분기.

**Why:** 양품에 조치 안내 불필요. 불필요한 RAG 호출 방지.

**How to apply:** 검사 결과 수신 후 `quality_state` 기준으로 Router 분기. good → Screen 5 (정상, 검사계속하기 + 저장). defect → Screen 4 (결함, 조치카드 + 저장 + 보고).

---

## 4. 조치 카드 데이터 구조 (Layer 4 귀속)

**결정:** `GuidanceResponse`에 `cause`, `reinspection_criteria`, `disclaimer` 추가. 모두 Layer 4 — Restoration Layer 귀속.

```python
class GuidanceResponse(BaseModel):
    ontology_id: str
    display_label: str
    quality_state: Literal["good", "defect"]
    cause: str
    action_steps: list[str]
    reinspection_criteria: str
    disclaimer: str
    referenced_doc: str | None = None
```

---

## 5. API 응답 식별자 체계 (ontology-expert 자문 반영)

**결정:** `defect_name` 단일 한글 필드 제거. 아래 필드 조합으로 교체.

| 필드 | 용도 | 레이어 |
|------|------|--------|
| `ontology_id` | 심각도 룩업, RAG 키 | Layer 4 |
| `display_label` | Flutter UI 표시 | Layer 4 |
| `canonical_class_name` | 모델 클래스 추적 | Layer 3 |
| `quality_state` | 화면 분기 | Layer 4 |
| `annotation_domain` | 도메인 분기 | Layer 2 |

**Why:** 한글 결함명만으로는 part_name 복원 불가. `confidence_to_severity` 함수는 도메인 설계 위반 (confidence ≠ 위험도).

---

## 6. Grad-CAM MVP 포함

**결정:** Grad-CAM 토글 MVP에 포함.

**Why:** 포트폴리오 시각적 차별화. "AI가 어디를 보고 판단했는지" 설명 기능이 핵심 가치 제안.

**How to apply:** ML 서버 추론 파이프라인에 Grad-CAM 생성 단계 추가. `gradcam_key` S3 업로드. Flutter ImageOverlayViewer에 토글 구현.

SIREN 관리자 대시보드 PRD

1. 제품 개요
   SIREN 관리자 대시보드는 현장 검사원이 Flutter 앱에서 수행한 LNG 탱크 부품 검사 결과를 관리자가 웹에서 확인하고, 결함 발생 현황과 검사 이력을 관찰할 수 있는 품질 관리 보조 도구이다.

현장 앱이 “검사 수행”에 집중한다면, 관리자 대시보드는 “검사 결과 모니터링”과 “품질 상태 파악”에 집중한다.

관리자 대시보드는 단순 결함 라벨 목록이 아니라, 백엔드가 제공하는 ontology 기반 필드를 활용해 결함을 도메인, 세부 유형, 품질 상태 기준으로 분류·필터링·집계한다.

2. 문제 정의
   현재 현장 검사 프로세스는 다음과 같은 관리상의 한계를 가진다.

검사 결과가 개별 작업자 단위로 흩어져 있어 전체 품질 흐름을 보기 어렵다.
결함 유형별 발생 빈도나 최근 이상 징후를 빠르게 파악하기 어렵다.
AI 분석 결과와 조치 이력이 누적되어도 관리자가 활용할 수 있는 관찰 화면이 부족하다.
결함 라벨이 내부 코드 형태로만 노출되면 관리자가 의미를 직관적으로 이해하기 어렵다.
데모/운영 관점에서 “검사 데이터가 저장되고 관리된다”는 제품적 증거가 필요하다. 3. 목표
관리자가 웹 대시보드에서 검사 결과를 빠르게 관찰하고, 결함 발생 추이와 개별 검사 상세를 확인할 수 있도록 한다.

MVP 목표는 다음과 같다.

전체 검사 현황 요약
최근 검사 목록 확인
결함 유형별 분포 확인
ontology 기반 도메인/결함 필터링
검사 상세 결과 확인
AI confidence, severity, 조치 가이드 확인
정상/결함/미분류 품질 상태 구분
실패/대기/완료 분석 상태 구분 4. 타겟 유저
4.1 1차 유저: 품질 관리자
현장 검사 결과를 모니터링하고, 결함 발생 현황을 파악해야 하는 관리자.

주요 니즈:

오늘/최근 검사 결과를 빠르게 확인
결함 발생 건수와 정상 판정 건수 파악
위험도가 높은 검사 결과 확인
반복적으로 발생하는 결함 유형 파악
4.2 2차 유저: 공정 엔지니어
반복 결함 유형과 검사 데이터를 기반으로 공정 개선 포인트를 찾는 사용자.

주요 니즈:

특정 공정 도메인에서 결함이 몰리는지 확인
결함 유형별 발생 빈도 확인
AI confidence가 낮은 결함 유형 파악
향후 모델 개선 또는 데이터 품질 검토에 활용 5. 제품 원칙
Read-only 우선

MVP 대시보드는 검사 결과 관찰에 집중한다.
검사 수정, 삭제, 승인 워크플로우는 제외한다.
Ontology 기반 표시

내부 클래스명보다 사용자 친화적인 display_label을 우선 표시한다.
annotation_domain, ontology_id, quality_state를 필터와 집계 기준으로 활용한다.
불완전한 AI 결과를 명확히 표시

confidence, unknown 상태, failed 상태를 숨기지 않는다.
AI 판정은 최종 품질 판단이 아닌 보조 정보임을 명시한다.
데모 안정성

API 실패, 데이터 없음, 이미지 없음 상태에서도 화면이 깨지지 않아야 한다.
샘플 데이터 기반 시연이 가능해야 한다. 6. MVP 범위
6.1 포함 범위
영역 기능
Overview 총 검사 수, 결함 수, 정상 수, 실패 수, 평균 confidence
Inspection List 최근 검사 결과 테이블
Filter 상태, 품질 상태, 도메인, 결함 유형, severity, 날짜 필터
Detail 검사 이미지, 결함명, confidence, severity, ontology 정보, 조치 가이드
Analytics 결함 유형별 분포, 도메인별 결함 분포
상태 처리 pending, processing, completed, failed
빈 상태 데이터 없음, 필터 결과 없음, 이미지 없음
데모 mock/sample 데이터 기반 화면 표시 가능
6.2 제외 범위
검사 결과 수정/삭제
관리자 권한 세분화
실시간 WebSocket 모니터링
리포트 PDF 다운로드
CSV 다운로드
공정/라인별 고급 분석
알림 시스템
모델 성능 관리 전용 페이지
현장 작업자 계정 관리
오프라인 모드 7. 핵심 사용자 흐름
관리자 로그인
→ 대시보드 홈 진입
→ 전체 검사 현황 KPI 확인
→ 최근 검사 목록 확인
→ 상태/도메인/결함 유형 필터 적용
→ 특정 검사 클릭
→ 검사 이미지 및 AI 분석 결과 확인
→ ontology breadcrumb 확인
→ confidence, severity, 조치 가이드 확인 8. 주요 화면 요구사항
8.1 Dashboard Overview
관리자가 처음 진입하는 화면이다.

표시 정보
총 검사 수
결함 발견 수
정상 판정 수
분석 실패 수
평균 confidence
최근 검사 목록
결함 유형별 분포
도메인별 결함 분포
KPI 집계 기준
KPI 집계 기준
총 검사 수 inspections count
결함 발견 수 quality_state = defect
정상 판정 수 quality_state = normal
미분류 수 quality_state = unknown 또는 null
분석 실패 수 inspection.status = failed
평균 confidence completed 검사 중 confidence 평균
UI 구성
상단 KPI 카드
중앙 차트 영역
결함 유형별 분포
도메인별 결함 분포
하단 최근 검사 테이블
8.2 Inspection List
검사 결과 목록 화면이다.

테이블 컬럼
컬럼 설명
검사 ID inspection 고유 ID
검사 일시 생성 또는 완료 시간
작업자 inspector 이름 또는 ID
분석 상태 pending / processing / completed / failed
품질 상태 normal / defect / unknown
도메인 표면처리 / 용접 / 절단
결함 유형 display_label
severity low / medium / high
confidence AI confidence score
상세 상세 페이지 이동
필터
필터 설명
날짜 범위 검사 생성일 또는 완료일 기준
분석 상태 pending / processing / completed / failed
품질 상태 normal / defect / unknown
도메인 annotation_domain 기준
결함 유형 display_label 기준
severity low / medium / high
표시 규칙
결함명은 canonical_class_name 대신 display_label을 우선 표시한다.
display_label이 없으면 canonical_class_name을 fallback으로 표시한다.
annotation_domain이 없으면 “미분류”로 표시한다.
confidence가 없으면 “-”로 표시한다.
8.3 Inspection Detail
개별 검사 상세 화면이다.

표시 정보
원본 이미지
AI 분석 결과 이미지 또는 bbox/overlay
분석 상태
품질 상태
결함명 display_label
내부 클래스명 canonical_class_name
ontology ID
ontology breadcrumb
annotation domain
confidence
severity
RAG 조치 가이드
생성 시간
완료 시간
실패 시 error message
Ontology Breadcrumb
ontology_id를 기반으로 결함 분류 경로를 표시한다.

예시:

표면처리 > 스크래치 > 도장
구현 방식:

ontology_id = surface_treatment.scratch.paint
→ split(".")
→ slug label map으로 한글 표시
조치 가이드 구성
원인 추정
권장 조치
재검사 기준
주의사항
참고용 안내 문구
상세 화면 주의 문구
상세 화면에는 다음 의미의 안내를 표시한다.

AI 분석 결과는 현장 품질 판단을 보조하기 위한 참고 정보입니다.
최종 판정은 검사원 또는 품질 관리자의 확인이 필요합니다.
8.4 Analytics
간단한 품질 관찰 화면이다.

필수 차트
차트 설명
결함 유형별 분포 display_label 기준 count
도메인별 결함 분포 annotation_domain 기준 count
품질 상태 분포 normal / defect / unknown count
severity 분포 low / medium / high count
선택 차트
차트 설명
일자별 검사 건수 날짜별 inspection count
평균 confidence 추이 날짜별 평균 confidence
실패율 추이 날짜별 failed 비율 9. Ontology 데이터 요구사항
대시보드는 기존 DetectionItemCore가 제공하는 ontology 필드를 적극 활용한다.

필수 활용 필드
{
"canonical_class_name": "scratch_paint",
"ontology_id": "surface_treatment.scratch.paint",
"annotation_domain": "surface_treatment",
"display_label": "스크래치 (도장)",
"quality_state": "defect"
}
필드 설명
필드 설명 화면 활용
canonical_class_name 모델/백엔드 내부 정규 클래스명 상세 화면, fallback
ontology_id 계층형 결함 ID breadcrumb, analytics
annotation_domain 결함 도메인 필터, 차트
display_label 사용자 표시용 결함명 리스트/상세 기본 표시
quality_state normal / defect / unknown KPI, 필터, 차트
도메인 라벨 맵
값 화면 표시
surface_treatment 표면처리
welding 용접
cutting 절단
unknown 미분류 10. API 요구사항
마감 전 MVP에서는 백엔드 신규 개발을 최소화한다. 기존 검사/탐지 응답에 포함된 ontology 필드를 우선 사용한다.

단, 대시보드 전용 API를 추가할 경우 아래 구조를 따른다.

10.1 GET /api/dashboard/summary
대시보드 KPI 요약 반환.

응답 예시:

{
"total_inspections": 128,
"defect_count": 43,
"normal_count": 78,
"unknown_count": 3,
"failed_count": 7,
"average_confidence": 0.82
}
10.2 GET /api/dashboard/inspections
검사 목록 반환.

쿼리:

status
quality_state
annotation_domain
defect_type
severity
from
to
page
limit
응답 예시:

{
"items": [
{
"inspection_id": "uuid",
"inspector_id": "uuid",
"created_at": "2026-06-01T10:30:00",
"completed_at": "2026-06-01T10:30:07",
"status": "completed",
"quality_state": "defect",
"annotation_domain": "surface_treatment",
"canonical_class_name": "scratch_paint",
"ontology_id": "surface_treatment.scratch.paint",
"display_label": "스크래치 (도장)",
"severity": "medium",
"confidence": 0.87
}
],
"total": 128
}
10.3 GET /api/dashboard/inspections/{inspection_id}
검사 상세 반환.

응답 예시:

{
"inspection_id": "uuid",
"inspector_id": "uuid",
"image_url": "string",
"overlay_image_url": "string",
"status": "completed",
"quality_state": "defect",
"annotation_domain": "surface_treatment",
"canonical_class_name": "scratch_paint",
"ontology_id": "surface_treatment.scratch.paint",
"display_label": "스크래치 (도장)",
"severity": "medium",
"confidence": 0.87,
"guidance": {
"cause": "표면 처리 과정에서 도장면에 물리적 접촉이 발생했을 가능성이 있습니다.",
"action": "손상 부위를 확인하고 필요 시 재도장 또는 표면 보수를 진행합니다.",
"reinspection": "보수 후 동일 영역을 재촬영하여 결함 재발 여부를 확인합니다.",
"caution": "AI 조치 가이드는 참고용이며 최종 판단은 품질 관리자가 수행합니다."
},
"created_at": "2026-06-01T10:30:00",
"completed_at": "2026-06-01T10:30:07",
"error_message": null
}
10.4 GET /api/dashboard/analytics
차트용 통계 반환.

응답 예시:

{
"domain_distribution": [
{
"annotation_domain": "surface_treatment",
"display_label": "표면처리",
"count": 24
},
{
"annotation_domain": "welding",
"display_label": "용접",
"count": 8
}
],
"defect_type_distribution": [
{
"ontology_id": "surface_treatment.scratch.paint",
"display_label": "스크래치 (도장)",
"count": 12
}
],
"quality_state_distribution": [
{ "label": "normal", "count": 78 },
{ "label": "defect", "count": 43 },
{ "label": "unknown", "count": 3 }
],
"severity_distribution": [
{ "label": "low", "count": 20 },
{ "label": "medium", "count": 15 },
{ "label": "high", "count": 8 }
]
} 11. 상태 및 에러 처리
반드시 처리해야 하는 상태:

상태 처리 방식
검사 데이터 없음 빈 상태 메시지 표시
필터 결과 없음 필터 초기화 CTA 표시
API 서버 연결 실패 재시도 버튼 표시
이미지 로딩 실패 이미지 없음 placeholder 표시
guidance 없음 “조치 가이드 없음” 표시
confidence 없음 “-” 표시
ontology_id 없음 “미분류” 표시
display_label 없음 canonical_class_name fallback
분석 실패 error message 표시
권한 없음 로그인/권한 안내 표시 12. Human Test 계획
관리자 역할 사용자에게 다음 과제를 수행하게 한다.

테스트 과제
오늘 발생한 결함 검사 수를 확인한다.
정상 판정 수와 결함 발견 수를 비교한다.
표면처리 도메인의 결함만 필터링한다.
severity가 high인 검사를 찾는다.
특정 검사 상세에서 AI confidence와 조치 가이드를 확인한다.
가장 많이 발생한 결함 유형을 말한다.
분석 실패한 검사 건수를 찾는다.
측정 항목
항목 기준
과제 성공 여부 성공 / 실패
과제별 소요 시간 초 단위 기록
헷갈린 UI 요소 사용자 발화 기록
신뢰가 가지 않는 정보 사용자 발화 기록
추가로 보고 싶은 정보 자유 응답
목표
항목 목표
최근 검사 결과 찾기 30초 이내
high severity 검사 찾기 30초 이내
검사 상세 정보 이해 1분 이내
결함 유형 분포 이해 30초 이내 13. 성능 측정 항목
마감 전 최소 측정 대상:

항목 목표
대시보드 첫 화면 로딩 2초 이하
Summary API 응답 1초 이하
Inspection List API 응답 1초 이하
Inspection Detail API 응답 1.5초 이하
Analytics API 응답 1초 이하
100개 검사 데이터 렌더링 2초 이하
이미지 포함 상세 페이지 로딩 3초 이하
측정 결과는 README 또는 별도 문서에 기록한다.

14. 우선순위
    P0 — 마감 전 필수
    Overview KPI 카드
    quality_state 기준 정상/결함/미분류 집계
    최근 검사 테이블
    display_label 기반 결함명 표시
    annotation_domain 필터
    검사 상세 페이지
    상세 화면 ontology 정보 표시
    빈 상태/에러 상태 처리
    샘플 데이터 fallback
    P1 — 가능하면 구현
    Inspection Detail breadcrumb
    도메인별 결함 분포 차트
    결함 유형별 분포 차트
    도메인 label map 한글화
    날짜별 검사 추이
    severity 분포 차트
    P2 — 마감 후 확장
    캐스케이딩 필터
    confidence × defect type 분석
    taxonomy status 배지
    cross-domain annotation candidate 표시
    CSV 다운로드
    PDF 리포트
    실시간 알림
    모델 품질 피드백 화면
15. 성공 지표
    영역 지표 목표
    사용성 관리자가 최근 검사 결과를 찾는 시간 30초 이내
    관찰성 전체 검사 수/결함 수 확인 가능 여부 가능
    분류성 도메인/결함 유형 기준 필터 가능 여부 가능
    신뢰성 confidence/severity/AI 참고 문구 표시 여부 가능
    안정성 데이터 없음/오류 상태에서도 화면 유지 가능
    성능 대시보드 초기 로딩 2초 이내
    성능 검사 목록 API 응답 1초 이내
    데모 샘플 검사 상세 확인 100% 성공
16. MVP 완료 기준
    대시보드는 다음 조건을 만족하면 MVP 완료로 본다.

관리자가 전체 검사 현황을 한 화면에서 볼 수 있다.
quality_state 기준으로 정상/결함/미분류 수를 확인할 수 있다.
최근 검사 목록을 확인할 수 있다.
display_label 기준으로 결함명을 이해할 수 있다.
annotation_domain 기준으로 검사 결과를 필터링할 수 있다.
특정 검사의 상세 결과를 볼 수 있다.
상세 화면에서 ontology ID, 도메인, 결함명, confidence, severity를 확인할 수 있다.
RAG 조치 가이드를 확인할 수 있다.
분석 실패/대기/완료 상태가 구분된다.
데이터가 없거나 API가 실패해도 화면이 깨지지 않는다.
데모용 샘플 데이터로 안정적인 시연이 가능하다. 17. 구현 메모
마감 전 구현 전략:

백엔드 신규 개발을 최소화하고 기존 detection item 필드를 우선 활용한다.
API 연결이 불완전하면 mock/sample data로 UI를 먼저 완성한다.
display_label, annotation_domain, quality_state를 화면의 핵심 축으로 사용한다.
상세 화면은 데모 설득력이 높으므로 반드시 구현한다.
차트는 최소 1개, 가능하면 결함 유형별/도메인별 2개를 구현한다.
필터는 도메인 필터부터 우선 구현하고, 캐스케이딩 필터는 후순위로 둔다.
모든 수치와 차트에는 빈 상태 fallback을 둔다. 18. 핵심 요약
SIREN 관리자 대시보드는 현장 검사 앱에서 생성된 AI 검사 결과를 관리자가 관찰하기 위한 read-only 품질 관리 화면이다.

MVP의 핵심은 다음 세 가지다.

quality_state 기반 정상/결함 집계
display_label 기반 사용자 친화적 결함 표시
annotation_domain 및 ontology_id 기반 체계적 결함 분류
이를 통해 대시보드는 단순 검사 목록이 아니라, ontology 기반 품질 관찰 대시보드로 동작한다.

"""
guidance 테이블 18개 클래스 조치 카드 seed 스크립트 (idempotent).

사용법:
    cd api
    python scripts/seed_guidance.py
    python scripts/seed_guidance.py --dry-run
"""

import argparse
import asyncio
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

sys.path.insert(0, ".")

from app.core.config import settings
from app.models.guidance import Guidance

GUIDANCE_SEED = [
    {
        "ontology_id": "surface_treatment.crack.paint",
        "canonical_class_name": "crack_paint",
        "display_label": "균열 (도장)",
        "quality_state": "defect",
        "cause": "반복 하중, 열팽창·수축, 용접부 응력 집중으로 인한 도장면 균열",
        "action_steps": [
            "해당 구역 즉시 접근 통제",
            "균열 범위 마킹 및 사진 기록",
            "관리자 보고 후 보수팀 출동 요청",
            "승인된 도장 보수 절차 시행",
        ],
        "reinspection_criteria": "보수 완료 후 동일 구역 재촬영 및 AI 재검사 필수",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_crack_v1",
    },
    {
        "ontology_id": "surface_treatment.coating_drop.paint",
        "canonical_class_name": "coating_drop_paint",
        "display_label": "도막떨어짐 (도장)",
        "quality_state": "defect",
        "cause": "기재 표면 오염, 부착력 부족, 습기 침투로 인한 도막 박리",
        "action_steps": [
            "박리 구역 격리",
            "박리 범위 측정 기록",
            "표면 처리 후 재도장 절차 시행",
        ],
        "reinspection_criteria": "재도장 후 부착력 검사 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_coating_v1",
    },
    {
        "ontology_id": "surface_treatment.coating_separation.paint",
        "canonical_class_name": "coating_separation_paint",
        "display_label": "도막분리 (도장)",
        "quality_state": "defect",
        "cause": "층간 부착력 저하, 프라이머-탑코트 계면 박리",
        "action_steps": [
            "분리 구역 격리 및 범위 기록",
            "층간 밀착력 검사",
            "전면 재도장 여부 판단 후 시행",
        ],
        "reinspection_criteria": "재도장 완료 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_coating_v1",
    },
    {
        "ontology_id": "surface_treatment.paint_run.paint",
        "canonical_class_name": "paint_run_paint",
        "display_label": "도장흐름 (도장)",
        "quality_state": "defect",
        "cause": "과도한 도료 분사량 또는 불균일 도포로 인한 흘러내림",
        "action_steps": [
            "흐름 구역 사진 기록",
            "경화 후 연마 또는 재도장 여부 판단",
        ],
        "reinspection_criteria": "보수 후 육안 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_coating_v1",
    },
    {
        "ontology_id": "surface_treatment.insulation_damage.insulation",
        "canonical_class_name": "insulation_damage_insulation",
        "display_label": "보온재손상 (보온재)",
        "quality_state": "defect",
        "cause": "외부 충격, 수분 침투, 노후화로 인한 보온재 훼손",
        "action_steps": [
            "손상 구역 격리",
            "수분 침투 여부 확인",
            "손상 보온재 교체 시행",
        ],
        "reinspection_criteria": "교체 완료 후 열화상 검사 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_insulation_v1",
    },
    {
        "ontology_id": "surface_treatment.scratch.paint",
        "canonical_class_name": "scratch_paint",
        "display_label": "스크래치 (도장)",
        "quality_state": "defect",
        "cause": "작업 중 도구 접촉, 운반 중 마찰로 인한 도장면 긁힘",
        "action_steps": [
            "스크래치 범위 기록",
            "부식 진행 여부 확인",
            "터치업 도장 시행",
        ],
        "reinspection_criteria": "터치업 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_scratch_v1",
    },
    {
        "ontology_id": "surface_treatment.scratch.base_material",
        "canonical_class_name": "scratch_base_material",
        "display_label": "스크래치 (모재)",
        "quality_state": "defect",
        "cause": "모재 직접 긁힘, 방청 처리 손상",
        "action_steps": [
            "모재 손상 깊이 측정",
            "방청 처리 후 도장 재시공",
        ],
        "reinspection_criteria": "재시공 후 두께 측정 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_surface_scratch_v1",
    },
    {
        "ontology_id": "surface_treatment.scratch.insulation",
        "canonical_class_name": "scratch_insulation",
        "display_label": "스크래치 (보온재)",
        "quality_state": "defect",
        "cause": "보온재 표면 손상으로 단열 성능 저하 위험",
        "action_steps": [
            "손상 위치 기록",
            "단열 성능 저하 여부 점검",
            "필요 시 보온재 보수",
        ],
        "reinspection_criteria": "보수 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_insulation_v1",
    },
    {
        "ontology_id": "surface_treatment.tank_cleaning_defect.base_material",
        "canonical_class_name": "tank_cleaning_defect_base_material",
        "display_label": "탱크클리닝불량 (모재)",
        "quality_state": "defect",
        "cause": "클리닝 공정 불량으로 잔류 이물질 또는 오염 존재",
        "action_steps": [
            "오염 구역 격리",
            "재클리닝 시행",
            "클리닝 품질 기준 재확인",
        ],
        "reinspection_criteria": "재클리닝 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cleaning_v1",
    },
    {
        "ontology_id": "welding.weld_defect.joint",
        "canonical_class_name": "weld_defect_joint",
        "display_label": "용접불량 (조인트)",
        "quality_state": "defect",
        "cause": "용접 파라미터 불량, 용접사 기량 미달로 인한 조인트 결함",
        "action_steps": [
            "해당 조인트 작업 중단",
            "비파괴검사(NDT) 의뢰",
            "결함부 재용접 또는 교체",
        ],
        "reinspection_criteria": "재용접 후 NDT 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_welding_v1",
    },
    {
        "ontology_id": "welding.weld_blowhole.joint",
        "canonical_class_name": "weld_blowhole_joint",
        "display_label": "용접블루홀 (조인트)",
        "quality_state": "defect",
        "cause": "용접 중 가스 포집으로 인한 기공(블로우홀) 발생",
        "action_steps": [
            "기공 위치 마킹",
            "그라인딩 후 재용접",
            "NDT 재검사",
        ],
        "reinspection_criteria": "재용접 완료 후 초음파 검사 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_welding_v1",
    },
    {
        "ontology_id": "cutting.cut_defect.base_material",
        "canonical_class_name": "cut_defect_base_material",
        "display_label": "절단불량 (모재)",
        "quality_state": "defect",
        "cause": "절단 파라미터 오설정 또는 절단 장비 불량으로 인한 모재 절단 결함",
        "action_steps": [
            "절단 결함 범위 기록",
            "절단면 재가공 여부 판단",
            "필요 시 재절단",
        ],
        "reinspection_criteria": "재가공 후 치수 검사 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cutting_v1",
    },
    {
        "ontology_id": "cutting.cut_defect.insulation",
        "canonical_class_name": "cut_defect_insulation",
        "display_label": "절단불량 (보온재)",
        "quality_state": "defect",
        "cause": "보온재 절단 불량으로 단열 간극 또는 형상 불일치 발생",
        "action_steps": [
            "절단 불량 위치 기록",
            "보온재 재절단 또는 교체",
        ],
        "reinspection_criteria": "교체 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cutting_v1",
    },
    {
        "ontology_id": "cable.binding_defect.cable_tie",
        "canonical_class_name": "binding_defect_cable_tie",
        "display_label": "바인딩불량 (케이블타이)",
        "quality_state": "defect",
        "cause": "케이블타이 미체결 또는 이완으로 인한 케이블 고정 불량",
        "action_steps": [
            "이완 케이블타이 위치 기록",
            "케이블타이 재체결 또는 교체",
        ],
        "reinspection_criteria": "재체결 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cable_v1",
    },
    {
        "ontology_id": "cable.cable_install_defect.cable_gland",
        "canonical_class_name": "cable_install_defect_cable_gland",
        "display_label": "케이블설치불량 (케이블그랜드)",
        "quality_state": "defect",
        "cause": "케이블그랜드 미조임 또는 오설치로 인한 방수/방폭 기능 손상",
        "action_steps": [
            "그랜드 체결 상태 확인",
            "재조임 또는 교체",
            "방수 테스트 시행",
        ],
        "reinspection_criteria": "조치 완료 후 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cable_v1",
    },
    {
        "ontology_id": "cable.cable_damage.cable",
        "canonical_class_name": "cable_damage_cable",
        "display_label": "케이블손상 (케이블)",
        "quality_state": "defect",
        "cause": "외피 손상, 굽힘 반경 초과, 압착으로 인한 케이블 절연 훼손",
        "action_steps": [
            "손상 케이블 즉시 전원 차단",
            "손상 범위 기록",
            "케이블 교체",
        ],
        "reinspection_criteria": "교체 후 절연 저항 측정 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_cable_v1",
    },
    {
        "ontology_id": "pipe.bolt_defect.pipe",
        "canonical_class_name": "bolt_defect_pipe",
        "display_label": "볼트체결불량 (파이프)",
        "quality_state": "defect",
        "cause": "토크 미달 또는 볼트 손상으로 인한 파이프 플랜지 체결 불량",
        "action_steps": [
            "체결 불량 플랜지 위치 기록",
            "토크렌치로 재체결",
            "누설 점검",
        ],
        "reinspection_criteria": "재체결 후 누설 테스트 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_pipe_v1",
    },
    {
        "ontology_id": "foam_spray.foam_spray_defect.urethane_foam",
        "canonical_class_name": "foam_spray_defect_urethane_foam",
        "display_label": "폼스프레이불량 (우레탄폼)",
        "quality_state": "defect",
        "cause": "분사량 불균일 또는 경화 불량으로 인한 우레탄폼 시공 결함",
        "action_steps": [
            "불량 구역 범위 기록",
            "미경화 부분 제거 후 재시공",
        ],
        "reinspection_criteria": "재시공 후 두께 측정 및 AI 재검사",
        "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
        "referenced_doc": "sop_foam_v1",
    },
]


async def seed(dry_run: bool = False) -> None:
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as db:
        inserted = skipped = 0
        for row in GUIDANCE_SEED:
            existing = await db.scalar(
                select(Guidance).where(Guidance.ontology_id == row["ontology_id"])
            )
            if existing:
                if not dry_run:
                    for key, value in row.items():
                        setattr(existing, key, value)
                skipped += 1
            else:
                if not dry_run:
                    db.add(Guidance(**row))
                inserted += 1

        if not dry_run:
            await db.commit()

    await engine.dispose()

    mode = "[dry-run]" if dry_run else "[ok]"
    print(f"{mode} guidance seed 완료: insert={inserted}, upsert(update)={skipped}")


def main() -> None:
    parser = argparse.ArgumentParser(description="guidance 테이블 초기 데이터 적재")
    parser.add_argument(
        "--dry-run", action="store_true", help="DB 변경 없이 실행 계획만 출력"
    )
    args = parser.parse_args()
    asyncio.run(seed(dry_run=args.dry_run))


if __name__ == "__main__":
    main()

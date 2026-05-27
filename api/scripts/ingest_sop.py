"""
SOP 문서 → ChromaDB ingest 스크립트 (idempotent).

사용법:
    cd api
    python scripts/ingest_sop.py
    python scripts/ingest_sop.py --dry-run
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

DOMAIN_SLUGS: dict[str, str] = {
    "표면처리": "surface_treatment",
    "용접": "welding",
    "절단": "cutting",
    "케이블": "cable",
    "파이프": "pipe",
    "폼스프레이": "foam_spray",
}

DEFECT_SLUGS: dict[str, str] = {
    "균열": "crack",
    "도막떨어짐": "coating_drop",
    "도막분리": "coating_separation",
    "도장흐름": "paint_run",
    "보온재손상": "insulation_damage",
    "스크래치": "scratch",
    "탱크클리닝불량": "tank_cleaning_defect",
    "표면양품": "surface_good",
    "용접불량": "weld_defect",
    "용접블로우홀": "weld_blowhole",
    "용접양품": "weld_good",
    "절단불량": "cut_defect",
    "절단양품": "cut_good",
    "바인딩불량": "binding_defect",
    "바인딩양품": "binding_good",
    "케이블설치불량": "cable_install_defect",
    "케이블설치양품": "cable_install_good",
    "케이블손상": "cable_damage",
    "케이블양품": "cable_good",
    "볼트체결불량": "bolt_defect",
    "볼트체결양품": "bolt_good",
    "폼스프레이불량": "foam_spray_defect",
    "폼스프레이양품": "foam_spray_good",
}

PART_SLUGS: dict[str, str] = {
    "도장": "paint",
    "보온재": "insulation",
    "모재": "base_material",
    "우레탄폼": "urethane_foam",
    "조인트": "joint",
    "케이블타이": "cable_tie",
    "케이블그랜드": "cable_gland",
    "케이블": "cable",
    "파이프": "pipe",
}

SKIP_SECTIONS = {"RAG 검색 키워드"}

SECTION_ORDER = ["결함 개요", "원인", "조치 방법", "주의사항", "참고 기준"]

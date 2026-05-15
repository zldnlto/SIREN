"""
migrate.py — Google Drive 업로드 용
resized/ → images/ 신구조 마이그레이션 (idempotent)

실행:
  python migrate.py --dry-run      # 이동 목록 확인만
  python migrate.py                # 실제 실행
  python migrate.py --delete-old   # 복사 완료 후 원본 삭제
"""

import argparse
import re
import shutil
import time
from pathlib import Path

try:
    from colab_setup import OLD_IMAGES, NEW_IMAGES, MANIFESTS, METADATA
except ImportError:
    DRIVE_DATA = Path("/content/drive/MyDrive/siren/data")
    OLD_IMAGES = DRIVE_DATA / "resized"
    NEW_IMAGES = DRIVE_DATA / "images"
    MANIFESTS = DRIVE_DATA / "manifests"
    METADATA = DRIVE_DATA / "metadata"

LOG_PATH = METADATA / "migration.log"
TRAIN_MANIFEST = MANIFESTS / "train.txt"
VAL_MANIFEST = MANIFESTS / "val.txt"


# ── 매핑 테이블 ───────────────────────────────────────────────

PROCESS_MAP: dict[str, str] = {
    "표면처리": "surface",
    "용접": "welding",
    "케이블": "cable",
    "절단": "cutting",
    "파이프": "pipe",
    "폼스프레이": "foam",
}

# canonical class = defect_name × part_name
# 양품(normal)은 hard negative → NORMAL_MAP으로 분리
CLASS_MAP: dict[str, str] = {
    # surface
    "균열_도장": "crack_paint",
    "도막떨어짐_도장": "paint_peel_paint",
    "도막분리_도장": "paint_separation_paint",
    "도장흐름_도장": "paint_flow_paint",
    "보온재손상_보온재": "insulation_damage_insulation",  # fix: part_name 복원
    "스크래치_도장": "scratch_paint",
    "스크래치_모재": "scratch_base",
    "스크래치_보온재": "scratch_insulation",
    "탱크클리닝불량_모재": "cleaning_defect_base",
    # welding
    "용접불량_조인트": "weld_defect_joint",
    "용접블루홀_조인트": "weld_blowhole_joint",
    # cutting
    "절단불량_모재": "cut_defect_base",
    "절단불량_보온재": "cut_defect_insulation",
    # cable
    "바인딩불량_케이블타이": "binding_defect_cable_tie",
    "케이블설치불량_케이블그랜드": "cable_install_defect_gland",
    "케이블손상_케이블": "cable_damage_cable",  # fix: part_name 복원
    # pipe
    "볼트체결불량_파이프": "bolt_defect_pipe",
    # foam
    "폼스프레이불량_우레탄폼": "foam_spray_defect_urethane_foam",
}

# 양품 → hard negative (background), detection bbox 없는 이미지로 투입
NORMAL_MAP: dict[str, str] = {
    # surface
    "표면양품_도장": "background",
    "표면양품_모재": "background",
    "표면양품_보온재": "background",
    # welding
    "용접양품_조인트": "background",
    # cutting
    "절단양품_모재": "background",
    "절단양품_보온재": "background",
    # cable
    "바인딩양품_케이블타이": "background",
    "케이블설치양품_케이블그랜드": "background",
    "케이블양품_케이블": "background",
    # pipe
    "볼트체결양품_파이프": "background",
    # foam
    "폼스프레이양품_우레탄폼": "background",
}


# ── 폴더명 파싱 ───────────────────────────────────────────────

# migrate.py — parse_folder() 수정
import unicodedata


def parse_folder(folder_name: str) -> tuple[str, str, str] | None:
    clean = re.sub(r"\s*\(\d+\)\s*$", "", folder_name).strip()
    clean = unicodedata.normalize("NFC", clean)  # ← 추가
    parts = clean.split("_")
    if len(parts) < 4 or parts[0] not in ("TS", "VS"):
        return None
    split_prefix = parts[0]
    process_ko = parts[1]
    defect_material = "_".join(parts[2:])
    return split_prefix, process_ko, defect_material


# ── 경로 변환 ─────────────────────────────────────────────────


def resolve_dst(src: Path) -> tuple[Path, str] | None:
    """
    returns: (dst_path, split) | None
    split: 'train' | 'val'
    """
    for part in src.parts:
        parsed = parse_folder(part)
        if parsed is None:
            continue

        split_prefix, process_ko, defect_material = parsed
        process_en = PROCESS_MAP.get(process_ko)
        if not process_en:
            return None

        # 결함 클래스 우선, 없으면 양품(background) 확인
        class_en = CLASS_MAP.get(defect_material) or NORMAL_MAP.get(defect_material)
        if not class_en:
            return None

        split = "train" if split_prefix == "TS" else "val"
        dst = NEW_IMAGES / process_en / class_en / src.name
        return dst, split

    return None


# ── Log I/O ───────────────────────────────────────────────────


def load_log(log_path: Path) -> set[str]:
    if not log_path.exists():
        return set()
    return set(log_path.read_text(encoding="utf-8").splitlines())


def append_log(log_path: Path, entry: str) -> None:
    with log_path.open("a", encoding="utf-8") as f:
        f.write(entry + "\n")


def load_manifests(train_path: Path, val_path: Path) -> set[str]:
    """재실행 시 manifest 중복 기록 방지 — 기존 기록을 completed에 합산"""
    recorded: set[str] = set()
    for p in (train_path, val_path):
        if p.exists():
            recorded.update(p.read_text(encoding="utf-8").splitlines())
    return recorded


# ── 단일 파일 마이그레이션 ────────────────────────────────────


def migrate_file(
    src: Path,
    dst: Path,
    split: str,
    completed: set[str],
    dry_run: bool,
) -> str:
    """returns: 'skip' | 'dry' | 'done' | 'leakage' | 'error'"""
    dst_str = str(dst)

    if dst_str in completed:
        return "skip"

    if dst.exists():
        # TS 우선 원칙 — VS가 나중에 오면 leakage로 처리
        return "leakage" if split == "val" else "skip"

    if dry_run:
        print(f"  [DRY/{split}] {src.name}  →  {dst}")
        return "dry"

    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        append_log(LOG_PATH, dst_str)

        manifest = TRAIN_MANIFEST if split == "train" else VAL_MANIFEST
        append_log(manifest, str(dst))
        return "done"
    except Exception as e:
        print(f"  [ERROR] {src} → {e}")
        return "error"


# ── 전체 실행 ─────────────────────────────────────────────────


def run(dry_run: bool = False) -> None:
    METADATA.mkdir(parents=True, exist_ok=True)
    MANIFESTS.mkdir(parents=True, exist_ok=True)

    # fix: manifest 기존 기록도 completed에 합산 → 재실행 시 중복 방지
    completed = load_log(LOG_PATH)
    completed |= load_manifests(TRAIN_MANIFEST, VAL_MANIFEST)

    # fix: p.parts 기준 TS_ prefix 탐색 → 정렬 조건 수정
    all_files = sorted(
        OLD_IMAGES.rglob("*.jpg"),
        key=lambda p: (0 if any(part.startswith("TS_") for part in p.parts) else 1),
    )
    total = len(all_files)

    print(f"\n[migrate] 대상 파일: {total}개  |  dry_run={dry_run}")
    print(f"[migrate] log: {LOG_PATH}\n")

    counts = {"skip": 0, "dry": 0, "done": 0, "leakage": 0, "error": 0, "unmapped": 0}
    start = time.perf_counter()

    for i, src in enumerate(all_files, 1):
        result_pair = resolve_dst(src)

        if result_pair is None:
            counts["unmapped"] += 1
            print(f"  [UNMAPPED] {src}")
            continue

        dst, split = result_pair
        result = migrate_file(src, dst, split, completed, dry_run)
        counts[result] += 1

        if i % 1000 == 0:
            elapsed = time.perf_counter() - start
            print(
                f"  [{i}/{total}]"
                f"  done={counts['done']}"
                f"  leakage={counts['leakage']}"
                f"  skip={counts['skip']}"
                f"  {elapsed:.1f}s 경과"
            )

    elapsed = time.perf_counter() - start
    print(f"\n[migrate] 완료  ({elapsed:.1f}s)")
    for k, v in counts.items():
        print(f"  {k:<10}: {v}")

    if counts["unmapped"] > 0:
        print("\n  ⚠️  unmapped 파일 있어요. CLASS_MAP / PROCESS_MAP 확인 필요.")
    if counts["leakage"] > 0:
        print(
            f"\n  ℹ️  leakage {counts['leakage']}건 — TS 파일 우선 보존, VS 중복 제거됨."
        )
    if not dry_run and counts["done"] > 0:
        print("\n  원본 삭제는 별도 단계에서 진행하세요.")
        print("  확인 후 실행: python migrate.py --delete-old")


# ── 원본 삭제 ─────────────────────────────────────────────────


def delete_old() -> None:
    completed = load_log(LOG_PATH)
    if not completed:
        print("[delete-old] migration.log 비어있어요. migrate 먼저 실행하세요.")
        return

    deleted = 0
    for src in OLD_IMAGES.rglob("*.jpg"):
        result_pair = resolve_dst(src)
        if result_pair:
            dst, _ = result_pair
            if str(dst) in completed and dst.exists():
                src.unlink()
                deleted += 1

    print(f"[delete-old] 원본 삭제 완료: {deleted}개")


# ── CLI ───────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SIREN dataset migration")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--delete-old", action="store_true")
    args = parser.parse_args()

    if args.delete_old:
        delete_old()
    else:
        run(dry_run=args.dry_run)

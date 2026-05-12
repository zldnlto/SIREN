"""
테스트 유저 시드 스크립트.

사용법:
    cd api
    python scripts/seed_user.py
    python scripts/seed_user.py --employee-id EMP-999 --password secret --name 홍길동 --role ADMIN
"""

import argparse
import asyncio
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

sys.path.insert(0, ".")

from app.core.config import settings
from app.core.security import hash_password
from app.models.user import User


async def seed(employee_id: str, password: str, name: str, role: str) -> None:
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as db:
        existing = await db.scalar(select(User).where(User.employee_id == employee_id))
        if existing:
            print(f"[skip] employee_id='{employee_id}' 이미 존재합니다.")
            return

        user = User(
            employee_id=employee_id,
            password_hash=hash_password(password),
            name=name,
            role=role,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        print("[ok] 유저 생성 완료")
        print(f"     id          : {user.id}")
        print(f"     employee_id : {user.employee_id}")
        print(f"     name        : {user.name}")
        print(f"     role        : {user.role}")

    await engine.dispose()


def main() -> None:
    parser = argparse.ArgumentParser(description="테스트 유저 생성")
    parser.add_argument("--employee-id", default="EMP-001")
    parser.add_argument("--password", default="siren1234!")
    parser.add_argument("--name", default="테스트 검사원")
    parser.add_argument("--role", default="INSPECTOR", choices=["INSPECTOR", "ADMIN"])
    args = parser.parse_args()

    asyncio.run(seed(args.employee_id, args.password, args.name, args.role))


if __name__ == "__main__":
    main()

from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# root .env → api/.env 순으로 탐색 (Docker는 환경변수 직접 주입되므로 env_file 불사용)
_ROOT_ENV = Path(__file__).parent.parent.parent.parent / ".env"
_LOCAL_ENV = Path(__file__).parent.parent.parent / ".env"


class Settings(BaseSettings):
    API_PREFIX: str = "/api/v1"
    APP_NAME: str = "SIREN API"
    DEBUG: bool = False

    # DB (Sub-issue 1)
    DATABASE_URL: str = "postgresql+asyncpg://siren:siren@localhost:5432/siren"

    # Auth (Sub-issue 2) — SECRET_KEY는 환경변수 필수, 미설정 시 기동 불가
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # S3 (Sub-issue 5)
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_S3_BUCKET: str = "siren-inspections"
    AWS_S3_REGION: str = "ap-northeast-2"

    model_config = SettingsConfigDict(
        env_file=(_ROOT_ENV, _LOCAL_ENV),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("SECRET_KEY")
    @classmethod
    def secret_key_must_be_strong(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("SECRET_KEY는 32자 이상이어야 합니다.")
        return v


settings = Settings()

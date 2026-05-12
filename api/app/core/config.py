from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    API_PREFIX: str = "/api/v1"
    APP_NAME: str = "SIREN API"
    DEBUG: bool = False

    # DB (Sub-issue 1)
    DATABASE_URL: str = "postgresql+asyncpg://siren:siren@localhost:5432/siren"

    # Auth (Sub-issue 2)
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()

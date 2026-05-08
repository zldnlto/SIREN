from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    API_PREFIX: str = "/api/v1"
    APP_NAME: str = "SIREN API"
    DEBUG: bool = False

    # DB (Sub-issue 1)
    DATABASE_URL: str = "postgresql+asyncpg://siren:siren@localhost:5432/siren"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()

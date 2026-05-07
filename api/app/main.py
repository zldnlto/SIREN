from app.core.config import settings
from app.routers import health, inspections
from fastapi import FastAPI

app = FastAPI(title=settings.APP_NAME)

app.include_router(health.router)
app.include_router(inspections.router, prefix=settings.API_PREFIX)

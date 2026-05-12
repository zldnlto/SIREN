from app.core.config import settings
from app.routers import auth, health, inspections
from fastapi import FastAPI

app = FastAPI(title=settings.APP_NAME)

app.include_router(health.router)
app.include_router(auth.router, prefix=settings.API_PREFIX)
app.include_router(inspections.router, prefix=settings.API_PREFIX)

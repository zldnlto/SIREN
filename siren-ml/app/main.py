from __future__ import annotations

import asyncio

from fastapi import FastAPI
from pydantic import BaseModel

from app.inference import run_inference
from app.s3 import download_image

app = FastAPI(title="siren-ml", version="0.1.0")


class PredictRequest(BaseModel):
    image_key: str


class Detection(BaseModel):
    class_code: int
    class_name: str
    confidence: float
    bbox: list[float]


class PredictResponse(BaseModel):
    detections: list[Detection]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict", response_model=PredictResponse)
async def predict(req: PredictRequest):
    image_bytes = await asyncio.to_thread(download_image, req.image_key)
    detections = await asyncio.to_thread(run_inference, image_bytes)
    return PredictResponse(detections=[Detection(**d) for d in detections])

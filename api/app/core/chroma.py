import chromadb
from chromadb import Collection

from app.core.config import settings

COLLECTION_NAME = "siren_sop"

_client: chromadb.ClientAPI | None = None


def get_client() -> chromadb.ClientAPI:
    global _client
    if _client is None:
        _client = chromadb.HttpClient(
            host=settings.CHROMA_HOST, port=settings.CHROMA_PORT
        )
    return _client


def get_sop_collection() -> Collection:
    return get_client().get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )

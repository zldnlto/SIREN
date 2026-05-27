from chromadb import Collection


def get_by_ontology_id(collection: Collection, ontology_id: str) -> list[dict]:
    result = collection.get(
        where={"ontology_id": ontology_id},
        include=["documents", "metadatas"],
    )
    chunks = [
        {
            "section": m["section"],
            "content": d,
            "chunk_index": m["chunk_index"],
        }
        for d, m in zip(result["documents"], result["metadatas"])
    ]
    return sorted(chunks, key=lambda c: c["chunk_index"])

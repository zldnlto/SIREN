from chromadb import Collection


def get_by_ontology_id(
    collection: Collection,
    ontology_id: str,
    query_text: str | None = None,
) -> list[dict]:
    if query_text:
        result = collection.query(
            query_texts=[query_text],
            where={"ontology_id": ontology_id},
            n_results=10,
            include=["documents", "metadatas"],
        )
        docs = result["documents"][0]
        metas = result["metadatas"][0]
    else:
        result = collection.get(
            where={"ontology_id": ontology_id},
            include=["documents", "metadatas"],
        )
        docs = result["documents"]
        metas = result["metadatas"]

    chunks = [
        {
            "section": m["section"],
            "content": d,
            "chunk_index": m["chunk_index"],
        }
        for d, m in zip(docs, metas)
    ]
    return sorted(chunks, key=lambda c: c["chunk_index"])

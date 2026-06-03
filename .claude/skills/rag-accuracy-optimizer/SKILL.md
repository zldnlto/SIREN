---
name: rag-accuracy-optimizer
description: Optimize accuracy for RAG systems. Covers DB schema design, chunking strategies, retrieval optimization, accuracy testing, and anti-hallucination safeguards. Use when designing or improving a RAG pipeline, choosing chunking strategy, optimizing retrieval accuracy (hybrid search, reranking, multi-query), evaluating chunk quality, or setting up monitoring & safeguards for RAG production.
---

# RAG Accuracy Optimizer

A skill for optimizing end-to-end accuracy in RAG systems.

## Workflow Overview

```
Data Design → Chunking → Indexing → Retrieval → Generation → Testing → Monitoring
```

Each step impacts accuracy. Optimize each step in order.

---

## 1. Structured Data Design

### SQL vs Vector DB — When to Use What?

| Criteria | SQL (PostgreSQL, MySQL) | Vector DB (Pinecone, Qdrant, Weaviate) |
|----------|------------------------|----------------------------------------|
| Exact facts (price, date, product code) | ✅ Optimal | ❌ Not suitable |
| Semantic search (query meaning) | ❌ Not supported | ✅ Optimal |
| Aggregation (SUM, COUNT, AVG) | ✅ Native | ❌ Not supported |
| Fuzzy matching ("similar to...") | ⚠️ Limited | ✅ Optimal |
| Hybrid (recommended) | pgvector for both | Vector DB + SQL metadata store |

**Principle:** Clearly structured data → SQL. Unstructured data requiring semantic understanding → Vector DB. Most production systems need both.

### Metadata Tagging Strategy

Each chunk/document needs at minimum:

```python
metadata = {
    "source": "policy_doc_v2.pdf",
    "source_type": "pdf",
    "domain": "insurance",
    "category": "life_insurance",
    "entity_id": "POL-2024-001",
    "section": "exclusions",
    "chunk_index": 3,
    "total_chunks": 12,
    "created_at": "2024-01-15",
    "version": "2.0",
    "language": "en"
}
```

---

## 2. Chunking Strategies

### Choosing the Right Strategy

```
Data has clear structure (clauses, sections)?
  → Semantic chunking (by heading/section)

Long, continuous data (articles, transcripts)?
  → Fixed size + overlap (512 tokens, 10-20% overlap)

Need both overview + detail?
  → Hierarchical chunking (parent-child)

Domain-specific with its own logical units?
  → Domain-specific chunking
```

### Chunk Size Guidelines

| Size | Use case | Trade-off |
|------|----------|-----------|
| 128-256 tokens | FAQ, short definitions | High precision, less context |
| 256-512 tokens | Recommended default | Good balance |
| 512-1024 tokens | Complex text, legal docs | More context, potential noise |
| >1024 tokens | Rarely used | Too much noise |

### Overlap Strategy

- 10-20% overlap between adjacent chunks
- Ensures information at boundaries is not lost
- Chunk N ends with 1-2 opening sentences of chunk N+1

### Hierarchical Chunking (Parent-Child)

```
Document (summary)
  └── Section (heading + key points)
        └── Paragraph (details)
```

Search at paragraph level → when matched, pull parent section for additional context.

### Metadata Enrichment Per Chunk

Each chunk should be enriched with:
- **Summary**: 1-2 sentence content summary (LLM-generated)
- **Keywords**: Key terms (supports BM25)
- **Questions**: 2-3 questions this chunk can answer
- **Entities**: Named entities (product names, codes, dates)

---

## 3. Retrieval Optimization

### Recommended Retrieval Pipeline

```
User Query
  → Query Rewriting (expand/reformulate)
  → Multi-Query Generation (3-5 variants)
  → Metadata Filtering (narrow scope)
  → Hybrid Search (Vector + BM25)
  → Merge & Deduplicate
  → Reranking (top 20 → top 5)
  → Contextual Compression
  → LLM Generation (with citations)
```

### Hybrid Search (Vector + BM25)

```python
final_score = α × vector_score + (1-α) × bm25_score
# α = 0.7 is a good starting point, tune per domain
```

### Reranking

After retrieval, use a reranking model to re-sort by relevance:
- **Cohere Rerank**: Simple API, highly effective
- **Cross-encoder**: More accurate than bi-encoder, but slower
- **GPT Rerank**: Use LLM to evaluate relevance (expensive but flexible)

Retrieve top 20 → rerank → take top 3-5 for generation.

### Metadata Filtering

```python
# Instead of searching all 1M chunks:
filter = {"domain": "insurance", "product_type": "life"}
# Only search within ~50K relevant chunks
results = vector_db.search(query, filter=filter, top_k=20)
```

---

## 4. Accuracy Testing & Monitoring

### Test Suite Design

```json
{
    "test_cases": [
        {
            "question": "Does life insurance pay out for suicide?",
            "expected_answer": "No payout within the first 2 years",
            "expected_source": "clause_15_exclusions.pdf",
            "category": "exclusions",
            "difficulty": "medium"
        }
    ]
}
```

Minimum 50-100 test cases, evenly distributed across categories and difficulty levels.

### Metrics

| Metric | Meaning | Target |
|--------|---------|--------|
| Precision@K | % relevant results in top K | >0.8 |
| Recall@K | % ground truth found in top K | >0.9 |
| F1 | Harmonic mean of Precision and Recall | >0.85 |
| MRR | Mean Reciprocal Rank | >0.8 |
| NDCG | Normalized Discounted Cumulative Gain | >0.85 |
| Answer Accuracy | % correct answers | >0.9 |

### Error Analysis Framework

| Error Type | Cause | Solution |
|------------|-------|----------|
| Retrieval Miss | Correct chunk not found | Improve chunking, add hypothetical Q |
| Ranking Error | Correct chunk found but ranked low | Add reranking |
| Generation Error | Correct chunk but LLM answers wrong | Improve prompt, add few-shot |
| No Answer | Information not in DB | Expand knowledge base |
| Hallucination | LLM fabricates information | Add citation enforcement |

---

## 5. Safeguards

### Hallucination Prevention

```
Answer ONLY based on the information provided in the context.
If you cannot find the information, respond: "I could not find this
information in the available data."
NEVER fabricate information.
```

### Confidence Thresholds

```python
if max_relevance_score < 0.3:
    return "No relevant information found."
elif max_relevance_score < 0.6:
    return answer + "\n⚠️ Low confidence. Please verify."
else:
    return answer + f"\n📎 Source: {sources}"
```

---

## 6. Embedding Model Selection

| Scenario | Model | Reason |
|----------|-------|--------|
| Production, budget OK | Cohere embed-v4 | Highest MTEB, input_type optimization |
| Production, low cost | OpenAI text-embedding-3-small | $0.02/1M tokens, good quality |
| Self-host, multilingual | BGE-M3 | Hybrid dense+sparse, 100+ languages, free |
| POC / Prototype | all-MiniLM-L6-v2 | 90MB, runs on CPU |

**Key Principles:**
- Always `normalize_embeddings=True` for cosine similarity
- Batch processing (256-2000 items) instead of one at a time
- Use the **same model** for indexing and querying

---

## 7. Advanced Techniques

### Late Chunking
Embed the full document first, then pool by chunk boundaries — each chunk retains context from surrounding text. Quality gain: +5-10%.

### RAPTOR
Build a multi-level summary tree: chunks → section summaries → document summary. Use when answering both broad and narrow queries. Quality gain: +10-15%.

### GraphRAG
Build a knowledge graph → detect communities → summarize → query via map-reduce. Use for multi-hop reasoning across many documents. Quality gain: +15-25% for synthesis queries.

### Production Stack (Combined)
```
1. Late Chunking → better embeddings
2. Hybrid Search (BM25 + vector) → high recall
3. Reranking (Cohere/Cross-encoder) → high precision
4. RAPTOR → multi-level retrieval (optional)
5. GraphRAG → synthesis queries (optional, high cost)
```

---

## 8. Performance Optimization

### Caching Layer

```python
def cached_embed(text, model):
    key = f"emb:{hashlib.md5(text.encode()).hexdigest()}"
    cached = r.get(key)
    if cached:
        return json.loads(cached)
    embedding = model.encode([text])[0].tolist()
    r.setex(key, 3600, json.dumps(embedding))
    return embedding
```

### Async Retrieval

```python
async def parallel_retrieve(query, retrievers):
    tasks = [r.search(query) for r in retrievers]
    results = await asyncio.gather(*tasks)
    return merge_and_deduplicate(results)
```

---

## Scripts

- `scripts/eval_ragas.py` — RAGAS evaluation pipeline
- `scripts/embedding_benchmark.py` — Benchmark embedding models
- `scripts/chunk_optimizer.py` — Evaluate chunk quality
- `scripts/accuracy_test.py` — Test framework for RAG accuracy

## References

- `references/chunking-patterns.md` — Python code examples for chunking strategies
- `references/retrieval-patterns.md` — Hybrid search, reranking, multi-query
- `references/embedding-models.md` — Detailed embedding model comparison
- `references/vector-db-comparison.md` — Vector DB comparison + HNSW tuning
- `references/advanced-rag.md` — Late Chunking, RAPTOR, GraphRAG
- `references/testing-frameworks.md` — RAGAS, LLM-as-Judge, Adversarial testing

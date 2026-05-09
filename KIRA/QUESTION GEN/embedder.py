"""
Multilingual embeddings + ChromaDB vector store.

Model: paraphrase-multilingual-MiniLM-L12-v2
  - Supports 50+ languages including Arabic and English
  - 384-dim embeddings
  - Fast enough to run on CPU
"""

import chromadb
import uuid
from sentence_transformers import SentenceTransformer

# Multilingual model — handles Arabic and English equally well
EMBED_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"


class Embedder:
    def __init__(self, persist_dir: str = "./chroma_store"):
        print("[Embedder] Loading multilingual embedding model...")
        self.model  = SentenceTransformer(EMBED_MODEL)
        self.client = chromadb.PersistentClient(path=persist_dir)
        print("[Embedder] Ready.")

    # ── Document management ───────────────────────────────────────────────────

    def add_document(self, document_id: str, chunks: list[str], metadata: dict = None):
        """Embed and store all chunks for a document."""
        collection = self.client.get_or_create_collection(
            name=f"doc_{document_id}",
            metadata={"hnsw:space": "cosine"},
        )

        embeddings = self.model.encode(chunks, show_progress_bar=True).tolist()
        ids        = [str(uuid.uuid4()) for _ in chunks]
        metas      = [{"chunk_index": i, **(metadata or {})} for i in range(len(chunks))]

        collection.add(
            documents=chunks,
            embeddings=embeddings,
            ids=ids,
            metadatas=metas,
        )
        print(f"[Embedder] Stored {len(chunks)} chunks for document '{document_id}'.")

    def delete_document(self, document_id: str):
        try:
            self.client.delete_collection(f"doc_{document_id}")
        except Exception:
            pass

    def document_exists(self, document_id: str) -> bool:
        try:
            self.client.get_collection(f"doc_{document_id}")
            return True
        except Exception:
            return False

    # ── Retrieval ─────────────────────────────────────────────────────────────

    def retrieve(
        self,
        document_id: str,
        query:       str,
        top_k:       int = 5,
    ) -> list[str]:
        """Return the top-k most relevant chunks for a query."""
        collection  = self.client.get_collection(f"doc_{document_id}")
        query_embed = self.model.encode([query]).tolist()
        results     = collection.query(
            query_embeddings=query_embed,
            n_results=min(top_k, collection.count()),
        )
        return results["documents"][0]   # list of chunk strings

    def get_random_chunks(self, document_id: str, n: int = 5) -> list[str]:
        """Return n chunks without a specific query — used for broad generation."""
        collection = self.client.get_collection(f"doc_{document_id}")
        total      = collection.count()
        results    = collection.get(limit=min(n * 3, total))
        chunks     = results["documents"]
        # Space them out to cover different parts of the document
        step   = max(1, len(chunks) // n)
        return [chunks[i * step] for i in range(min(n, len(chunks)))]

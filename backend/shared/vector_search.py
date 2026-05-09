import math
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional

class BaseVectorProvider(ABC):
    @abstractmethod
    async def get_embedding(self, text: str) -> List[float]:
        pass

    @abstractmethod
    async def search_similar(self, query_embedding: List[float], collection: List[Dict[str, Any]], top_k: int = 5) -> List[Dict[str, Any]]:
        pass

class LocalVectorProvider(BaseVectorProvider):
    """
    A simple in-memory vector provider using cosine similarity.
    Perfect for development and small catalogs.
    """
    
    async def get_embedding(self, text: str) -> List[float]:
        # In a real app, this would call an LLM or use a local model.
        # For MVP/Dev, we generate a deterministic "mock" embedding based on word counts.
        words = text.lower().split()
        embedding = [0.0] * 128
        for word in words:
            # Deterministic hash to map word to an index
            idx = sum(ord(c) for c in word) % 128
            embedding[idx] += 1.0
            
        # Normalize
        norm = math.sqrt(sum(x*x for x in embedding))
        if norm > 0:
            embedding = [x/norm for x in embedding]
        return embedding

    async def search_similar(self, query_embedding: List[float], collection: List[Dict[str, Any]], top_k: int = 5) -> List[Dict[str, Any]]:
        results = []
        for item in collection:
            item_embedding = item.get("embedding")
            if not item_embedding:
                continue
                
            score = self._cosine_similarity(query_embedding, item_embedding)
            results.append({**item, "similarity": score})
            
        # Sort by similarity descending
        results.sort(key=lambda x: x["similarity"], reverse=True)
        return results[:top_k]

    def _cosine_similarity(self, v1: List[float], v2: List[float]) -> float:
        if len(v1) != len(v2):
            return 0.0
        
        dot_product = sum(a * b for a, b in zip(v1, v2))
        magnitude1 = math.sqrt(sum(a * a for a in v1))
        magnitude2 = math.sqrt(sum(b * b for b in v2))
        
        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0
            
        return dot_product / (magnitude1 * magnitude2)

class VertexAIVectorProvider(BaseVectorProvider):
    """
    Integration with Google Vertex AI Embeddings.
    (Requires google-cloud-aiplatform)
    """
    def __init__(self, project_id: str, location: str = "us-central1"):
        self.project_id = project_id
        self.location = location
        # Initialization would happen here if we had the library
        
    async def get_embedding(self, text: str) -> List[float]:
        # Placeholder for real Vertex AI call
        # In production: aiplatform.init(project=self.project_id, location=self.location)
        # model = TextEmbeddingModel.from_pretrained("text-embedding-004")
        # embeddings = model.get_embeddings([text])
        # return embeddings[0].values
        return [0.0] * 768 # Mock size

    async def search_similar(self, query_embedding: List[float], collection: List[Dict[str, Any]], top_k: int = 5) -> List[Dict[str, Any]]:
        # This might be implemented via Vector Search (Matching Engine) in Vertex AI
        # For now, fallback to local similarity check on the retrieved collection
        local = LocalVectorProvider()
        return await local.search_similar(query_embedding, collection, top_k)

# Factory function
def get_vector_provider() -> BaseVectorProvider:
    # Use environment variable or config to decide
    # For now, default to LocalVectorProvider
    return LocalVectorProvider()

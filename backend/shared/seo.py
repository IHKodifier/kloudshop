from typing import Dict, Any, List
from datetime import datetime

def generate_article_jsonld(post: Any, tenant_id: str, base_url: str = "") -> Dict[str, Any]:
    """Generates JSON-LD Article structured data for a blog post."""
    return {
        "@context": "https://schema.org",
        "@type": "BlogPosting",
        "mainEntityOfPage": {
            "@type": "WebPage",
            "@id": f"{base_url}/blog/{post.slug}"
        },
        "headline": post.title,
        "description": post.excerpt,
        "image": post.cover_image_url,
        "datePublished": post.published_at.isoformat() if post.published_at else post.created_at.isoformat(),
        "dateModified": post.updated_at.isoformat() if post.updated_at else post.created_at.isoformat(),
        "author": {
            "@type": "Organization",
            "name": tenant_id
        },
        "publisher": {
            "@type": "Organization",
            "name": tenant_id,
            "logo": {
                "@type": "ImageObject",
                "url": f"{base_url}/logo.png" # Placeholder
            }
        }
    }

def generate_product_jsonld(product: Any, variants: List[Any], tenant_id: str, base_url: str = "") -> Dict[str, Any]:
    """Generates JSON-LD Product structured data for a product."""
    offers = []
    for v in variants:
        offers.append({
            "@type": "Offer",
            "sku": v.sku,
            "price": float(v.price),
            "priceCurrency": "USD", # Default
            "availability": "https://schema.org/InStock", # Default for MVP
            "url": f"{base_url}/products/{product.slug}"
        })

    return {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": product.title,
        "description": product.description,
        "image": product.images if hasattr(product, 'images') else [],
        "sku": variants[0].sku if variants else None,
        "brand": {
            "@type": "Brand",
            "name": tenant_id
        },
        "offers": offers
    }

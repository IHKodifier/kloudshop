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

    images = []
    if hasattr(product, 'images') and product.images:
        images = product.images
    elif hasattr(product, 'image_url') and product.image_url:
        images = [product.image_url]

    return {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": product.title,
        "description": product.description,
        "image": images,
        "sku": variants[0].sku if variants else None,
        "brand": {
            "@type": "Brand",
            "name": tenant_id
        },
        "offers": offers
    }

def generate_meta_tags(
    title: str,
    description: str,
    url: str,
    image: str = None,
    site_name: str = "KloudShop"
) -> Dict[str, str]:
    """Generates a standard set of meta tags for HTML rendering."""
    tags = {
        "title": title,
        "description": description,
        "url": url,
        "image": image or f"{url}/logo.png", # Fallback
        "site_name": site_name
    }
    return tags

from fastapi import Request
from typing import List

def resolve_locale(request: Request, supported_locales: List[str]) -> str:
    """
    Resolve the locale from the request.
    Priority:
    1. Query param 'lang' (e.g. ?lang=fr)
    2. Header 'Accept-Language' (e.g. 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7')
    3. Default to first supported locale (fallback to 'en')
    """
    # 1. Query Parameter
    lang = request.query_params.get("lang")
    if lang and lang in supported_locales:
        return lang
        
    # 2. Accept-Language Header
    accept_lang = request.headers.get("Accept-Language")
    if accept_lang:
        # Simple parsing: take the first one that matches
        # Example: fr-CH, fr;q=0.9, en;q=0.8 -> ['fr-CH', ' fr;q=0.9', ' en;q=0.8']
        parts = accept_lang.split(",")
        for part in parts:
            # Extract 'fr' from 'fr-CH' or ' fr;q=0.9'
            clean_lang = part.split(";")[0].split("-")[0].strip().lower()
            if clean_lang in supported_locales:
                return clean_lang
                
    # 3. Default Fallback
    return supported_locales[0] if supported_locales else "en"

# app/services.py
import json
import logging
import requests
import urllib.parse
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- RATE-LIMIT RESILIENCY CONTRACT ---
# Automatically traps 429 errors and backs off smoothly instead of crashing
retry_policy = types.HttpRetryOptions(
    initial_delay=2.0,
    attempts=5,
    exp_base=2,
    http_status_codes=[429, 500, 503]
)

http_config = types.HttpOptions(
    retry_options=retry_policy,
    timeout=60 * 1000
)

try:
    client = genai.Client(api_key=settings.GEMINI_API_KEY, http_options=http_config)
    logger.info("Resilient Free Google AI Studio Client safely online.")
except Exception as e:
    logger.error(f"Failed to engage Gemini Client: {e}")
    raise e

class ContentKit(BaseModel):
    blog_markdown: str = Field(description="The complete technical blog post written in clean Markdown format.")
    image_prompt: str = Field(description="A descriptive, detailed, short 1-sentence prompt for an AI image generator.")
    linkedin_copy: str = Field(description="An engaging promotional LinkedIn post summary with hashtags.")

class SuggestionItem(BaseModel):
    title: str
    brief_outline: str

class SuggestionsList(BaseModel):
    ideas: list[SuggestionItem]

def generate_trend_suggestions() -> list[dict]:
    """Generates automated recommendation objects using resilient free structures."""
    prompt = "Brainstorm exactly 3 unique, highly engaging portfolio blog post ideas for a DevOps engineering intern."
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=SuggestionsList,
                temperature=0.7
            )
        )
        data = json.loads(response.text)
        return data.get('ideas', [])
    except Exception as e:
        logger.error(f"Trend compilation fallback tripped: {e}")
        return [
            {"title": "TIL: Configuring CI/CD Cache Pipelines", "brief_outline": "How to optimize deployment runtime parameters cleanly."}
        ]

def build_comprehensive_content(topic: str, insights: str | None, code: str | None) -> dict:
    """Uses grammar-constrained free execution grids to compile media assets."""
    system_instruction = (
        "You are an elite full-stack and DevOps engineer ghostwriting a technical community blog post. "
        "Your task is to take user constraints, logs, and build a unified content kit. "
        "The blog post must be written in an encouraging 'Today I Learned' (TIL) framework. "
        "You MUST include a dedicated section titled '🛑 Common Pitfalls and Gotchas' highlighting configuration traps. "
        "If code is provided, rewrite it using industry best practices with thorough engineering comments."
    )
    
    user_prompt = f"Topic Target: {topic}\nRaw Notes: {insights or 'N/A'}\nCode Block Input: {code or 'N/A'}"
    
    try:
        logger.info("Shipping payload schema request to Gemini free infrastructure...")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                response_schema=ContentKit,
                temperature=0.4
            )
        )
        
        parsed_data = json.loads(response.text)
        
        # Free Image Generation Pipeline Link Attachment
        raw_prompt = parsed_data.get('image_prompt', 'software engineering matrix banner')
        encoded_prompt = urllib.parse.quote(raw_prompt)
        free_image_url = f"https://image.pollinations.ai/p/{encoded_prompt}?width=1024&height=512&nologo=true&seed=42"
        
        parsed_data['live_image_url'] = free_image_url
        return parsed_data

    except Exception as e:
        logger.error(f"Content kit structural evaluation failure: {e}")
        raise e

def publish_to_channels(title: str, body: str, targets: dict) -> dict:
    status_report = {}
    if targets.get('devto'):
        try:
            url = "https://dev.to/api/articles"
            headers = {"Content-Type": "application/json", "api-key": settings.DEVTO_API_KEY}
            payload = {"article": {"title": title, "published": False, "body_markdown": body, "tags": ["devops", "automation"]}}
            res = requests.post(url, headers=headers, json=payload, timeout=8)
            status_report['devto'] = "Success (Draft)" if res.status_code == 201 else f"Failed ({res.status_code})"
        except Exception as e:
            status_report['devto'] = f"Connection Exception: {e}"
    return status_report
from openai import AsyncOpenAI
from src.mirrowchan.config import OPENAI_API_KEY


if not OPENAI_API_KEY:
    raise EnvironmentError("❌ OPENAI_API_KEY ist nicht gesetzt!")

# Asynchroner OpenAI-Client
openai_client = AsyncOpenAI(api_key=OPENAI_API_KEY)

import os
from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

API_ID = os.getenv("TELEGRAM_API_ID")

API_HASH = os.getenv("TELEGRAM_API_HASH")

INPUT_CHANNEL = os.getenv("INPUT_CHANNEL")

OUTPUT_CHANNEL = os.getenv("OUTPUT_CHANNEL")

SYSTEM_PROMPT = "You are a professional translation assistant. \
                Translate HTML-formatted text into fluent, natural-sounding German while preserving the original meaning. \
                Maintain all HTML tags and emojis exactly as in the original. \
                A certain amount of stylistic freedom is allowed to improve clarity, tone, and flow in German. \
                Do not add any comments, explanations, or formatting outside of the original text. \
                Return only the translated HTML. \
                Do not use cyrillic letters."
USER_PROMPT = "Translate the following HTML-formatted text into German: "

LANGUAGE_MODEL = "gpt-4-turbo"

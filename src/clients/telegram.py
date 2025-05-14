from telethon import TelegramClient
from src.config import TELEGRAM_API_ID, TELEGRAM_API_HASH

telegram_client = TelegramClient(
    "user", api_id=TELEGRAM_API_ID, api_hash=TELEGRAM_API_HASH
)
telegram_client.parse_mode = "html"

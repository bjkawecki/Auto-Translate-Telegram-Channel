from telethon import TelegramClient
from src.teletranchan.config import API_ID, API_HASH

telegram_client = TelegramClient("user", api_id=API_ID, api_hash=API_HASH)
telegram_client.parse_mode = "html"

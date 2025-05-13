from telethon import TelegramClient, events
from dotenv import load_dotenv
import os
from openai import AsyncOpenAI
from collections import defaultdict
import asyncio

load_dotenv()
# Zwischenspeicher für Gruppen (Alben)
album_cache = defaultdict(list)

API_ID = os.getenv("TELEGRAM_API_ID")
API_HASH = os.getenv("TELEGRAM_API_HASH")

INPUT_CHANNEL = "test_kanal_999"
LANGUAGE_MODEL = "gpt-4-turbo"
OUTPUT_CHANNEL = "test_kanal_999R"

telegram_client = TelegramClient("user", api_id=API_ID, api_hash=API_HASH)
telegram_client.parse_mode = "html"

openai_client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
SYSTEM_PROMPT = "You are a professional translation assistant. \
                Translate HTML-formatted text into fluent, natural-sounding German while preserving the original meaning. \
                Maintain all HTML tags and emojis exactly as in the original. \
                A certain amount of stylistic freedom is allowed to improve clarity, tone, and flow in German. \
                Do not add any comments, explanations, or formatting outside of the original text. \
                Return only the translated HTML."
USER_PROMPT = "Translate the following HTML-formatted text into German: "


# Funktion zum Bearbeiten des Textes via OpenAI
async def translate_text_with_openai(html_text: str) -> str:
    response = await openai_client.chat.completions.create(
        model=LANGUAGE_MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": USER_PROMPT + html_text},
        ],
        max_tokens=4096,
    )
    response_text = response.choices[0].message.content
    return response_text


# Starte Session (Einmal musst du dich mit deinem Telegram-Login-Code authentifizieren)
@telegram_client.on(events.NewMessage(chats=INPUT_CHANNEL))
async def message_handler(event):
    message = event.message

    # Album-Nachricht (Teil eines Albums)
    if message.grouped_id:
        album_cache[message.grouped_id].append(message)

        # Warten, ob noch weitere Teile kommen (kleine Verzögerung)
        await asyncio.sleep(1.5)

        # Wenn alle Teile vermutlich da sind:
        if len(album_cache[message.grouped_id]) >= 2:
            messages = album_cache.pop(message.grouped_id)

            # Optional: kombinierten Text aus allen Nachrichten
            full_text = "\n\n".join(m.text or "" for m in messages if m.text)
            translated_text = await translate_text_with_openai(full_text)

            files = [m.media for m in messages if m.media]
            await telegram_client.send_file(
                OUTPUT_CHANNEL,
                file=files,
                caption=translated_text[:1024],  # Telegram caption-Limit
                parse_mode="html",
            )
        return  # nicht weiter ausführen

    # Einzelne Nachricht
    html_text = message.text or ""
    translated_text = await translate_text_with_openai(html_text)
    if message.media:
        await telegram_client.send_file(
            OUTPUT_CHANNEL,
            file=message.media,
            caption=translated_text[:1024],
            parse_mode="html",
        )
    else:
        await telegram_client.send_message(
            OUTPUT_CHANNEL, translated_text, parse_mode="html"
        )


telegram_client.start()
print("⏳ Lausche auf neue Posts...")
telegram_client.run_until_disconnected()

from telethon import events
from src.teletranchan.config import INPUT_CHANNEL, OUTPUT_CHANNEL
from src.teletranchan.clients.telegram import telegram_client
from src.teletranchan.utils import album_cache
from src.teletranchan.services.translation import translate_text_with_openai
import asyncio
import logging


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
            try:
                translated_text = await translate_text_with_openai(full_text) | ""
            except Exception as e:
                translated_text = "⚠️ Übersetzungsfehler"
                logger = logging.getLogger(__name__)
                logger.exception(f"⚠️ Unerwarteter Übersetzungsfehler: {e}")

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

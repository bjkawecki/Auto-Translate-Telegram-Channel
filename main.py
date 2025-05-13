import asyncio
import signal
import sys
import threading
import time

from telethon.errors import SessionPasswordNeededError

from src.teletranchan.clients.telegram import telegram_client
from src.teletranchan.config import PASSWORD, PHONE
from src.teletranchan.logger import logger
from src.teletranchan.server import code_from_user, run_flask, code_callback
from src.teletranchan.services.messages import message_handler


# async def code_callback():
#     global code_from_user
#     while code_from_user is None:
#         await asyncio.sleep(1)
#     print("Code empfangen:", code_from_user)
#     return code_from_user


async def start_bot():
    try:
        print("VERBUNDEN: ", telegram_client.is_connected())
        await telegram_client.start(
            phone=PHONE,
            code_callback=code_callback,
            password=PASSWORD,
        )
        print("VERBUNDEN: ", telegram_client.is_connected())

        await telegram_client.run_until_disconnected()
    except SessionPasswordNeededError:
        logger.error("❌ Zwei-Faktor-Authentifizierung erforderlich!")
    except Exception as e:
        logger.exception(f"❌ Unerwarteter Fehler beim Starten des Bots: {e}")


def stop_telegram_bot(signal, frame):
    logger.info("Beende den Telegram-Bot...")
    telegram_client.disconnect()  # Trennt die Verbindung zum Telegram-Server
    sys.exit(0)  # Beendet das Programm


if __name__ == "__main__":
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True  # Setzt den Thread als Daemon-Thread, damit er beendet wird, wenn das Hauptprogramm beendet wird.
    flask_thread.start()
    asyncio.run(start_bot())


signal.signal(signal.SIGINT, stop_telegram_bot)  # Hört auf das CTRL+C Signal

import asyncio

from telethon.errors import SessionPasswordNeededError

from src.clients.telegram import telegram_client
from src.config import TELEGRAM_2FA_PASSWORD, PHONE, OUTPUT_CHANNEL
from src.logger import logger
from src.server import code_callback, run_quart
from src.services.messages import message_handler


async def start_bot():
    try:
        if not telegram_client.is_connected():
            logger.info("Not connected. Start webserver...")
            task_quart = asyncio.create_task(run_quart())

        await telegram_client.start(
            phone=PHONE,
            code_callback=code_callback,
            # password=TELEGRAM_2FA_PASSWORD,
        )
        logger.info(
            f"Connection {'established.' if telegram_client.is_connected() else 'not established.'}"
        )
        await telegram_client.send_message(
            OUTPUT_CHANNEL, "✅ Testnachricht von Telethon!"
        )
        if "task_quart" in locals():
            task_quart.cancel()
            try:
                await task_quart  # Warten, bis der Task tatsächlich abgebrochen wird
            except asyncio.CancelledError:
                logger.info("Quart-Server wurde gestoppt.")
        await telegram_client.run_until_disconnected()
    except SessionPasswordNeededError:
        logger.error("❌ Zwei-Faktor-Authentifizierung erforderlich!")
    except Exception as e:
        logger.exception(f"❌ Unerwarteter Fehler beim Starten des Bots: {e}")


async def main():
    # Den Event-Loop läuft so lange, bis die Verbindung getrennt wird
    await start_bot()


if __name__ == "__main__":
    asyncio.run(main())

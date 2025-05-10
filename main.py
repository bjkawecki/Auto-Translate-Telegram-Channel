# main.py
import logging
from src.teletranchan.clients.telegram import telegram_client
from src.teletranchan.services.messages import message_handler


def main():
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
    )
    logger = logging.getLogger(__name__)

    try:
        telegram_client.start()
        logger.info("🚀 Bot gestartet – lausche auf neue Nachrichten...")
        telegram_client.run_until_disconnected()
    except Exception as e:
        logger.exception(f"❌ Unerwarteter Fehler beim Starten des Bots: {e}")


if __name__ == "__main__":
    main()

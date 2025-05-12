# main.py
import logging
from src.teletranchan.clients.telegram import telegram_client
from src.teletranchan.services.messages import message_handler
from telethon.errors import SessionPasswordNeededError

# Logger einrichten
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


# Callback-Funktion für den Bestätigungscode
def get_code():
    # Manuelle Eingabe des Codes (falls du ihn manuell eingeben willst)
    return input("Bitte gib den Bestätigungscode ein: ")


async def main():
    # TelegramClient erstellen

    try:
        # Starten und mit der Telefonnummer verbinden
        await telegram_client.start(phone_number="", code_callback=get_code)
        logger.info("🚀 Bot gestartet – Lausche auf neue Nachrichten...")

        # Sobald der Code verifiziert ist, läuft der Bot
        await telegram_client.run_until_disconnected()

    except SessionPasswordNeededError:
        # Wenn 2FA aktiviert ist, musst du das Passwort eingeben
        logger.error("❌ Zwei-Faktor-Authentifizierung erforderlich!")
    except Exception as e:
        logger.exception(f"❌ Unerwarteter Fehler beim Starten des Bots: {e}")


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())

import asyncio
import signal
from threading import Event

from hypercorn.asyncio import serve
from hypercorn.config import Config
from quart import Quart, render_template, request
from src.mirrowchan.clients.telegram import telegram_client

from src.mirrowchan.logger import logger

app = Quart(__name__)
code_from_user = None

code_event = Event()


async def code_callback():
    if not telegram_client.is_connected():
        logger.info("Not connected. Start webserver...")
        task_quart = asyncio.create_task(run_quart())
        await asyncio.gather(task_quart)
        logger.info(
            f"Connection {'established.' if telegram_client.is_connected() else 'not established.'}"
        )

    while not code_event.is_set():
        await asyncio.sleep(1)

    # if task_quart:
    #     task_quart.cancel()
    #     try:
    #         await task_quart  # Warten, bis der Task tatsächlich abgebrochen wird
    #     except asyncio.CancelledError:
    #         logger.info("Quart-Server wurde gestoppt.")

    return code_from_user


@app.route("/")
async def home():
    return await render_template("index.html")


@app.route("/submit_code", methods=["POST"])
async def submit_code():
    global code_from_user
    form = await request.form
    code_from_user = form["code"]
    logger.info("Empfangener Code:", code_from_user)
    code_event.set()
    return "Code gespeichert"


shutdown_event = asyncio.Event()


def _signal_handler() -> None:
    shutdown_event.set()


async def run_quart():
    loop = asyncio.get_event_loop()
    loop.add_signal_handler(signal.SIGTERM, _signal_handler)
    config = Config()
    config.bind = ["0.0.0.0:8000"]
    logger.info("quart configured")
    loop.run_until_complete(
        await serve(app, config, shutdown_trigger=shutdown_event.wait)
    )

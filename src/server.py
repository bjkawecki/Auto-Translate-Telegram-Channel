import asyncio
import signal
from threading import Event

from hypercorn.asyncio import serve
from hypercorn.config import Config
from quart import Quart, render_template, request
from src.clients.telegram import telegram_client

from src.logger import logger

app = Quart(__name__)
code_from_user = None

code_event = Event()


async def code_callback():
    while not code_event.is_set():
        await asyncio.sleep(1)
    return code_from_user


@app.route("/")
async def home():
    return await render_template("index.html")


@app.route("/submit_code", methods=["POST"])
async def submit_code():
    global code_from_user
    form = await request.form
    code_from_user = form["code"]
    logger.info(f"Empfangener Code: {code_from_user}")
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

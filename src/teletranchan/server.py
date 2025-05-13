from flask import Flask, request, render_template
from threading import Event
import asyncio

app = Flask(__name__)
code_from_user = None


code_from_user = None
code_event = Event()


async def code_callback():
    while not code_event.is_set():
        await asyncio.sleep(0.5)
    print()
    return code_from_user


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/submit_code", methods=["POST"])
def submit_code():
    global code_from_user
    code_from_user = request.form["code"]
    code_event.set()
    return "Code gespeichert"


def run_flask():
    app.run(host="0.0.0.0", port=5000)

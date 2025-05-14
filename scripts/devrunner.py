import subprocess
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

SCRIPT_PATH = "src/main.py"


class RestartOnChange(FileSystemEventHandler):
    def __init__(self):
        self.process = None
        self.start_script()

    def start_script(self):
        self.process = subprocess.Popen(["python3", SCRIPT_PATH])

    def stop_script(self):
        if self.process and self.process.poll() is None:
            self.process.terminate()
            self.process.wait()

    def on_modified(self, event):
        if event.src_path.endswith(SCRIPT_PATH):
            print("🔄 Änderung erkannt, starte neu...")
            self.stop_script()
            self.start_script()

    def cleanup(self):
        self.stop_script()


if __name__ == "__main__":
    event_handler = RestartOnChange()
    observer = Observer()
    observer.schedule(event_handler, path=".", recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        event_handler.cleanup()
    observer.join()

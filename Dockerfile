FROM python:3.13-slim

# Setze das Arbeitsverzeichnis im Container
WORKDIR /tmp/project

# Kopiere main.py und requirements.txt in das Arbeitsverzeichnis
COPY requirements.txt .
COPY main.py .
COPY src src

# Installiere Python-Abhängigkeiten
RUN pip install --no-cache-dir -r requirements.txt

# Starte das Skript beim Containerstart
CMD ["python", "main.py"]
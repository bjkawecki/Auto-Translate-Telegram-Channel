# Echo-Chan
![Logo](assets/logo.png)

**Echo-Chan** is a Telegram bot that receives messages from an input channel, translates them, and forwards them to an output channel. The bot uses OpenAI GPT to translate the messages and utilizes the Telegram API for communication.

## How it works
- The bot listens for incoming messages in a Telegram input channel.
- It translates the text using OpenAI GPT and sends it along with any associated media to an output channel.
- The bot can also process album messages that contain multiple parts of a single message.


## Project structure

```text
.
├── main.py
├── src/      
│    ├── config.py
│    ├── clients/ 
│    │   ├── openai.py
│    │   └── telegram.py
│    ├── services/
│    │   ├── messages.py
│    │   └── translation.py
│    ├── templates/
│    │   └── index.html
│    └── utils.py
```

## Requirements
- Python 3.13
- An OpenAI API key
- A Telegram API ID
- A Telegram API Hash

## AWS Setup Overview

![aws-setup.svg](assets/aws-setup.svg)

This setup uses one single Availability Zone, one public subnet, and one EC2 instance.

It's definitely not production-ready,there's no high availability, no horizontal scaling, and everything sits in a public subnet.

However, the goal here was to keep things simple and easy to follow for training and learning purposes.

## Installation
### 1. Create a virtual environment
Create a virtual environment to isolate dependencies:
```bash
python -m venv venv
```

Activate the virtual environment:
- Linux/macOS:
```bash
source venv/bin/activate
```

- Windows:
```bash
venv\Scripts\activate
```
### 2. Install dependencies
Install all required dependencies defined in requirements.txt:
```bash
pip install -r requirements.txt
```

### 3. Configure environment variables
Create a .env file in the root directory and add your API keys and tokens:

```bash
OPENAI_API_KEY=<your-openai-api-key>
TELEGRAM_API_ID=<your-telegram-api-id>
TELEGRAM_API_HASH=<your-telegram-api-hash>
INPUT_CHANNEL=<your-input-channel-id>
OUTPUT_CHANNEL=<your-output-channel-id>
```

### 4. Start the app
Start the bot with the following command:
```bash
python main.py
```
After login, the app will begin listening for messages in the INPUT_CHANNEL and send them to the OUTPUT_CHANNEL after translation.

## License
This project is licensed under the MIT License.
# Teletran-Chan

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Amazon_Web_Services-FF9900?style=flat-square&logo=amazonwebservices&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=flat-square&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python-FFD43B?style=flat-square&logo=python&logoColor=blue)
![Telethon](https://img.shields.io/badge/Telethon-2CA5E0?style=flat-square&logo=telegram&logoColor=white)
![ChatGPT](https://img.shields.io/badge/OpenApi-74aa9c?style=flat-square&logo=openai&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=flat-square&logo=flask&logoColor=white)
![Github-Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white)


![Logo](assets/logo.png)

**Teletran-Chan** is a Telegram app that receives messages from an input channel, translates them, and forwards them to an output channel. The app uses OpenAI GPT to translate the messages and utilizes the Telegram API for communication.

## Table of Contents    

1. **[How it works](#how-it-works)**
2. **[Project structure](#usage)**
3. **[Requirements](#requirements)**
4. **[AWS Setup Overview](#aws-setup-overview)**
5. **[EC2 Setup Overview](#ec2-setup-overview)**
6. **[Local Installation](#local-installation)**
7. **[CI/CD Flow](#cicd-flow)**
8. **[License](#license)**

## How it works
- The app listens for incoming messages in a Telegram input channel.
- It translates the text using OpenAI GPT and sends it along with any associated media to an output channel.
- The app can also process album messages that contain multiple parts of a single message.


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

However, the goal here was to keep things simple and easy to follow for training and learning purposes, especially Terraform.

## EC2 Setup Overview
![aws-setup.svg](assets/ec2-setup.png)

The Flask server is secured as well as possible for now. It runs on an open HTTP port 80 (not secure!), but access is restricted to the committing admin’s IP address, which is provided as a variable during `terraform apply`.

Once the user successfully logs in via the Telegram API, the Flask server shuts down. The Telethon event loop takes over and continuously handles incoming requests and events, managing the interaction with the Telegram channels.

## CI/CD Data Flow

1. When the `main` branch of the GitHub repository is updated, a GitHub Action is triggered.

2. The workflow zips the updated source code and uploads it to an S3 bucket.

3. Upon detecting a new object in the S3 bucket, an AWS Lambda function is invoked.

4. The Lambda function terminates the existing EC2 instance.

5. The Auto Scaling Group launches a new EC2 instance automatically.

6. During instance launch, the `user-data` script:
    - Downloads the source code from the S3 bucket
    - Builds a new Docker image
    - Starts the container

7. Inside the container:
    - Dependencies are installed
    - `main.py` is executed


## Automation – with a Manual Checkpoint

The deployment process is fully automated up to the point where the application requires Telegram authentication.

Since Telegram sends a login code to an existing device, this step must be done manually.

To simplify that, a temporary Flask web server runs on the EC2 instance, allowing the user to enter the code. Once submitted, the server shuts down automatically.

> **Not secure for production – no authentication on the Flask form.**

## Local Installation
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
Start the app with the following command:
```bash
python main.py
```
After login, the app will begin listening for messages in the INPUT_CHANNEL and send them to the OUTPUT_CHANNEL after translation.

## License
This project is licensed under the MIT License.
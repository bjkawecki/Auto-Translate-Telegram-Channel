import os
from dotenv import load_dotenv
import boto3
from botocore.exceptions import ClientError
import json

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

API_ID = os.getenv("TELEGRAM_API_ID")

API_HASH = os.getenv("TELEGRAM_API_HASH")

INPUT_CHANNEL = os.getenv("INPUT_CHANNEL")

OUTPUT_CHANNEL = os.getenv("OUTPUT_CHANNEL")

SYSTEM_PROMPT = "You are a professional translation assistant. \
                Translate HTML-formatted text into fluent, natural-sounding German while preserving the original meaning. \
                Maintain all HTML tags and emojis exactly as in the original. \
                A certain amount of stylistic freedom is allowed to improve clarity, tone, and flow in German. \
                Do not add any comments, explanations, or formatting outside of the original text. \
                Return only the translated HTML. \
                Do not use cyrillic letters."
USER_PROMPT = "Translate the following HTML-formatted text into German: "

LANGUAGE_MODEL = "gpt-4-turbo"


def get_secret_openapikey():
    openapikey = "openapikey"
    telegram_api_id = "telegram_api_id"
    telegram_api_hash = "telegram_api_hash"
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        # Retrieve secrets from AWS Secrets Manager
        get_openapikey_value_response = client.get_secret_value(SecretId=openapikey)
        get_telegram_api_id_value_response = client.get_secret_value(
            SecretId=telegram_api_id
        )
        get_telegram_api_hash_value_response = client.get_secret_value(
            SecretId=telegram_api_hash
        )
    except ClientError as e:
        raise e

    # Parse the SecretString (which is a JSON string) into a dictionary
    openai_secret = json.loads(get_openapikey_value_response["SecretString"])
    telegram_api_id_secret = json.loads(
        get_telegram_api_id_value_response["SecretString"]
    )
    telegram_api_hash_secret = json.loads(
        get_telegram_api_hash_value_response["SecretString"]
    )

    # Extract the specific values from the parsed dictionaries
    OPENAI_API_KEY = openai_secret["OPENAI_API_KEY"]
    API_ID = int(telegram_api_id_secret["TELEGRAM_API_ID"])  # Convert to int
    API_HASH = telegram_api_hash_secret["TELEGRAM_API_HASH"]

    return OPENAI_API_KEY, API_ID, API_HASH


OPENAI_API_KEY, API_ID, API_HASH = get_secret_openapikey()

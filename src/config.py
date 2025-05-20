import os
from dotenv import load_dotenv
import boto3
from botocore.exceptions import ClientError

load_dotenv()

region_name = "eu-central-1"


INPUT_CHANNEL = os.getenv("INPUT_CHANNEL")
OUTPUT_CHANNEL = os.getenv("OUTPUT_CHANNEL")
SYSTEM_PROMPT = "You are a professional translation assistant. \
                Translate HTML-formatted text into fluent, natural-sounding German while preserving the original meaning. \
                Maintain all HTML tags and emojis exactly as in the original. \
                A certain amount of stylistic freedom is allowed to improve clarity, tone, and flow in German. \
                Do not add any comments, explanations, or formatting outside of the original text. \
                Return only the translated HTML."
USER_PROMPT = "Translate the following HTML-formatted text into German: "
LANGUAGE_MODEL = "gpt-4-turbo"

mode = os.getenv("MODE", "prod")
DEV = False
if mode == "dev":
    DEV = True

if DEV:
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    TELEGRAM_API_ID = os.getenv("TELEGRAM_API_ID")
    TELEGRAM_API_HASH = os.getenv("TELEGRAM_API_HASH")
    PHONE = os.getenv("PHONE")
    TELEGRAM_2FA_PASSWORD = os.getenv("PASSWORD")
else:

    def get_openai_key(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_telegram_api_id(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_telegram_api_hash(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_phone_number(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_telegram_2fa_password(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_input_channel(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    def get_output_channel(parameter_name, with_decryption=True):
        try:
            ssm = boto3.client("ssm", region_name=region_name)
            response = ssm.get_parameter(
                Name=parameter_name, WithDecryption=with_decryption
            )
            return response["Parameter"]["Value"]
        except ClientError as e:
            raise e

    OPENAI_API_KEY = get_openai_key("/ttc-ec2/openapi-key")
    TELEGRAM_API_ID = get_telegram_api_id("/ttc-ec2/telegram-api-id")
    TELEGRAM_API_HASH = get_telegram_api_hash("/ttc-ec2/telegram-api-hash")
    PHONE = get_phone_number("/ttc-ec2/phone")
    TELEGRAM_2FA_PASSWORD = get_telegram_2fa_password("/ttc-ec2/telegram-password")
    INPUT_CHANNEL = get_input_channel("/ttc-ec2/input-channel")
    OUTPUT_CHANNEL = get_output_channel("/ttc-ec2/output-channel")

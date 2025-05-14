from src.mirrowchan.config import LANGUAGE_MODEL, SYSTEM_PROMPT, USER_PROMPT
from src.mirrowchan.clients.openai import openai_client


async def translate_text_with_openai(html_text: str) -> str:
    response = await openai_client.chat.completions.create(
        model=LANGUAGE_MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": USER_PROMPT + html_text},
        ],
        max_tokens=4096,
    )
    response_text = response.choices[0].message.content
    return response_text

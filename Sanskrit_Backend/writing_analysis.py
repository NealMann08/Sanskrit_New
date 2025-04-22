from flask import Flask, request, jsonify
import base64
from openai import OpenAI
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Initialize OpenAI client with API key
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def analyze_sanskrit_text(text: str) -> str:
    """Analyze typed Sanskrit text quality"""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": """You are a Sanskrit writing expert. Analyze text quality by:
1. Grammar and syntax correctness
2. Writing style and structure
3. Semantic accuracy
4. Overall readability
5. Common errors
Provide concise analysis without translation offers.""",
            },
            {
                "role": "user",
                "content": f"""Analyze this Sanskrit text writing quality:
{text}
""",
            },
        ],
        temperature=0.2,  # More factual responses
    )
    return response.choices[0].message.content


def analyze_sanskrit_image(image_base64: str) -> str:
    """Analyze handwritten Sanskrit quality"""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": """You are a Sanskrit handwriting expert. Analyze:
1. Character formation quality
2. Stroke clarity and consistency
3. Alignment and spacing
4. Overall legibility
5. Common handwriting errors
Provide concise analysis without translation requests.""",
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": "Analyze the handwriting quality of this Sanskrit text:",
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"},
                    },
                ],
            },
        ],
        temperature=0.2,
        max_tokens=500,  # Limit response length
    )
    return response.choices[0].message.content


if __name__ == "__main__":
    app.run(debug=True)

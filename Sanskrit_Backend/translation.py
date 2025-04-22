from flask import Flask, request, jsonify
from openai import OpenAI
import os
from dotenv import load_dotenv
import json
from firebase_admin import firestore

# Load environment variables
load_dotenv()

# Initialize OpenAI client with API key
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def generate_translation_exercise(
    client: OpenAI,
    user_id: str,
    firestore_client: firestore.Client,
) -> dict:
    """
    Generates structured translation exercises with Firestore user tracking
    """
    try:
        # Get/Create user document
        user_ref = firestore_client.collection("users").document(user_id)
        user_doc = user_ref.get()
        
        # Initialize user document if not exists
        if not user_doc.exists:
            user_ref.set({
                "used_words": [],
                "translation_exercises": 0,
                "created_at": firestore.SERVER_TIMESTAMP
            })

        # Get used words with empty list fallback
        used_words = user_doc.get("used_words") if user_doc.exists else []

        # Generate exercise with GPT
        prompt = f"""Generate a Sanskrit translation exercise with:
- One Sanskrit word (not in: {used_words})
- Transliteration
- English translation
- Example usage in a simple sentence

Format as JSON: {{"sanskrit": "", "transliteration": "", "translation": "", "example": ""}}"""
        
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            response_format={"type": "json_object"},
        )

        # Parse and validate response
        data = json.loads(response.choices[0].message.content)
        required_fields = ["sanskrit", "transliteration", "translation", "example"]
        if not all(field in data for field in required_fields):
            raise ValueError("Missing required fields in OpenAI response")

        sanskrit_word = data["sanskrit"].strip()
        translation = data["translation"].lower().strip()

        # Update user record
        batch = firestore_client.batch()
        batch.update(user_ref, {
            "used_words": firestore.ArrayUnion([sanskrit_word]),
            "translation_exercises": firestore.Increment(1),
            "last_active": firestore.SERVER_TIMESTAMP
        })
        batch.commit()

        return {
            "exercise": f"Translate: {sanskrit_word} ({data['transliteration']})\nExample: {data['example']}",
            "correct_answer": translation,
            "used_word": sanskrit_word
        }

    except json.JSONDecodeError as e:
        return {"error": f"Failed to parse exercise data: {str(e)}"}
    except firestore.TransportError as e:
        return {"error": f"Database error: {str(e)}"}
    except Exception as e:
        return {"error": f"Exercise generation failed: {str(e)}"}

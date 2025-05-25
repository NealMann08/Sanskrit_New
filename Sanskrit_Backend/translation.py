from flask import request, jsonify
from openai import OpenAI
import os
from dotenv import load_dotenv
import json
from firebase_admin import firestore
from firebase_utils import get_or_create_user, firestore_client
import logging

# Initialize logging
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Initialize OpenAI client with API key
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
REQUIRED_FIELDS = ["sanskrit", "transliteration", "translations", "example"]

def generate_translation_exercise(
    client: OpenAI,
    user_id: str,
) -> dict:
    """Generates translation exercises with Firestore transaction support"""
    try:
        user_ref = firestore_client.collection("users").document(user_id)
        
        # Transactionally get/create user document
        user_doc = get_or_create_user(user_ref)
        if not user_doc:
            logger.error("Failed to get/create user document")
            return {"error": "Failed to access user data"}
            
        # Get the document data and safely access used_words
        user_data = user_doc.to_dict()
        used_words = user_data.get('used_words', []) if user_data else []
        
        # Generate exercise with OpenAI
        prompt = f"""Generate a Sanskrit translation exercise with:
            - One Sanskrit word (not in: {used_words})
            - Transliteration
            - Multiple valid English translations

            Return JSON format: {{
                "sanskrit": "",
                "transliteration": "",
                "translations": ["translation1", "translation2", ...],
                "example": ""
            }}"""
        
        try:
            response = client.chat.completions.create(
                model='gpt-4-0125-preview',
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                response_format={"type": "json_object"},
            )
        except Exception as e:
            logger.error(f"OpenAI API error: {str(e)}")
            return {"error": "Failed to generate exercise"}

        # Parse and validate response
        try:
            data = json.loads(response.choices[0].message.content)
            if not all(field in data for field in REQUIRED_FIELDS):
                logger.error("Missing required fields in OpenAI response")
                return {"error": "Invalid exercise format from AI provider"}
                
            sanskrit_word = data["sanskrit"].strip()
            translations = [t.lower().strip() for t in data["translations"]]
            
            if not translations:
                logger.error("No translations provided")
                return {"error": "Invalid exercise format from AI provider"}
            
            if sanskrit_word in used_words:
                logger.warning(f"AI generated duplicate word: {sanskrit_word}")
                return {"error": "Generated word already exists, please try again"}
                
        except (json.JSONDecodeError, KeyError) as e:
            logger.error(f"Response parsing error: {str(e)}")
            return {"error": "Failed to process AI response"}

        # Transactionally update user document
        try:
            @firestore.transactional
            def update_transaction(transaction):
                transaction.update(user_ref, {
                    "used_words": firestore.ArrayUnion([sanskrit_word]),
                    "translation_exercises": firestore.Increment(1),
                    "last_active": firestore.SERVER_TIMESTAMP
                })

            update_transaction(firestore_client.transaction())
        except Exception as e:
            logger.error(f"Firestore transaction error: {str(e)}")
            return {"error": "Failed to update user progress"}

        return {
            "exercise": f"Translate: {sanskrit_word} ({data['transliteration']})",
            "correct_answers": translations,
            "example": data['example']
        }

    except Exception as e:
        logger.exception("Unexpected error in exercise generation")
        return {"error": "Exercise generation failed"}


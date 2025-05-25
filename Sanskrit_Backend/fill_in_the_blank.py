from openai import OpenAI
from flask import request
import random
from firebase_admin import firestore
from typing import Dict, List, Optional
from firebase_utils import get_or_create_user, firestore_client
import logging
import json

# Initialize logging
logger = logging.getLogger(__name__)

def generate_fill_in_the_blank(
    client: OpenAI,
    user_id: str,
) -> Dict:
    """
    Generates a Sanskrit fill-in-the-blank exercise with multiple choice options.
    Tracks used sentences in Firestore to prevent repetition.

    Args:
        client: OpenAI client instance
        user_id: Firebase user ID for tracking progress

    Returns:
        Dictionary containing:
        - exercise: The formatted exercise text
        - choices: List of possible answers
        - correct_answer: The correct answer number
    """
    try:
        # Get user document reference
        user_ref = firestore_client.collection("users").document(user_id)
        
        # Transactionally get/create user document
        user_doc = get_or_create_user(user_ref)
        if not user_doc:
            logger.error("Failed to get/create user document")
            return {"error": "Failed to access user data"}
            
        # Get the document data and safely access used_sentences
        user_data = user_doc.to_dict()
        used_sentences = user_data.get('used_sentences', []) if user_data else []
        
        # Format used sentences for the prompt
        used_sentences_str = ", ".join([f'"{s}"' for s in used_sentences]) if used_sentences else "none"

        # Generate exercise
        prompt = (
            "Generate one beginner-level fill-in-the-blank Sanskrit exercise.\n"
            f"Previously used sentences: {used_sentences_str}\n"
            "Do not use any of the previously used sentences.\n"
            "Do not provide the English translation at all.\n"
            "Use this structure and replace the [Verb] with a blank:\n"
            "Sentence: [Subject] + [Verb] + [Object]\n\n"
            "Return the response in this exact JSON format:\n"
            "{\n"
            '    "sentence": "Full Sanskrit sentence with ___ for blank",\n'
            '    "options": ["option1", "option2", "option3"],\n'
            '    "correct_option": 1\n'
            "}"
        )

        exercise_completion = client.chat.completions.create(
            model="gpt-4-0125-preview",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher. Generate exercises in JSON format."},
                {"role": "user", "content": prompt}
            ],
            temperature=1.2,
            response_format={"type": "json_object"},
        )

        # Parse the response
        try:
            data = json.loads(exercise_completion.choices[0].message.content)
            sentence = data["sentence"].strip()
            options = data["options"]
            correct_answer = data["correct_option"]
            
            if sentence in used_sentences:
                logger.warning(f"AI generated duplicate sentence: {sentence}")
                return {"error": "Generated sentence already exists, please try again"}
                
        except (json.JSONDecodeError, KeyError) as e:
            logger.error(f"Response parsing error: {str(e)}")
            return {"error": "Failed to process AI response"}

        # Randomize options while tracking correct answer
        correct_answer_text = options[correct_answer - 1]
        random.shuffle(options)
        new_correct_index = options.index(correct_answer_text) + 1

        # Format the exercise
        formatted_options = "\n".join(
            [f"# {i + 1}. {options[i]}" for i in range(len(options))]
        )
        exercise = f"Instructions: Identify which option best completes this sentence:\nSanskrit Sentence: {sentence}\nOptions:\n{formatted_options}"

        # Transactionally update user document
        try:
            @firestore.transactional
            def update_transaction(transaction):
                transaction.update(user_ref, {
                    "used_sentences": firestore.ArrayUnion([sentence]),
                    "fill_in_blank_exercises": firestore.Increment(1),
                    "last_active": firestore.SERVER_TIMESTAMP
                })

            update_transaction(firestore_client.transaction())
        except Exception as e:
            logger.error(f"Firestore transaction error: {str(e)}")
            return {"error": "Failed to update user progress"}

        return {
            "exercise": exercise,
            "choices": options,
            "correct_answer": str(new_correct_index),
        }

    except Exception as e:
        logger.error(f"Error generating exercise: {str(e)}", exc_info=True)
        return {
            "error": f"Error generating exercise: {str(e)}",
            "exercise": "",
            "choices": [],
            "correct_answer": None,
        }

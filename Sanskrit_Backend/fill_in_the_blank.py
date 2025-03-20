from openai import OpenAI
from flask import current_app
from flask_login import current_user
from bson.objectid import ObjectId
import random
from typing import Dict, List, Optional

def generate_fill_in_the_blank(client: OpenAI, used_sentences: Optional[List[str]] = None) -> Dict:
    """
    Generates a Sanskrit fill-in-the-blank exercise with multiple choice options.
    
    Args:
        client: OpenAI client instance
        used_sentences: List of previously used sentences (optional)
    
    Returns:
        Dictionary containing:
        - exercise: The formatted exercise text
        - choices: List of possible answers
        - correct_answer: The correct answer number
    """
    try:
        # Get used sentences from authenticated user or parameter
        if current_user.is_authenticated:
            used_sentences = current_user.used_sentences
        elif used_sentences is None:
            used_sentences = []
        
        # Format used sentences string
        used_sentences_str = ", ".join(used_sentences)
        
        # Generate exercise
        exercise_completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher."},
                {
                    "role": "user",
                    "content": f"""Generate one beginner-level fill-in-the-blank Sanskrit exercise.
The exercise should not be any of the following sentences: [{used_sentences_str}].
Do not provide the English translation at all.
Use this structure and replace the [Verb] or [Verb] with a blank:
Sentence: [Subject] + [Verb] + [Object]
Answer choices:
1. [Option 1]
2. [Option 2]
3. [Option 3]
Correct answer: [Correct option]
"""
                }
            ],
            temperature=1.2
        )
        
        # Format exercise
        exercise_response = exercise_completion.choices[0].message.content
        formatted_completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher. Format responses cleanly."},
                {
                    "role": "user",
                    "content": f"""
Use this Sanskrit fill-in-the-blank exercise: {exercise_response}
Format as:
<EXERCISE>
Instructions: Identify which option best completes this sentence:
Sanskrit Sentence: [Sentence with ___ for blank]
Options:
# 1. [Option 1]
# 2. [Option 2]
# 3. [Option 3]
</EXERCISE>
<ANSWER>
[Correct Option Number]
</ANSWER>
"""
                }
            ],
            temperature=0.7
        )
        
        # Parse the response
        response_text = formatted_completion.choices[0].message.content
        exercise = response_text.split("<EXERCISE>")[1].split("</EXERCISE>")[0].strip()
        correct_answer = response_text.split("<ANSWER>")[1].split("</ANSWER>")[0].strip()
        
        # Process options
        options = exercise.split("Options:")[1].strip().split("\n")
        options = [option.strip().split(". ", 1)[1] for option in options if ". " in option]
        
        # Get correct answer text and number
        correct_answer_num = int(correct_answer)
        correct_answer_text = options[correct_answer_num - 1]
        
        # Randomize options while tracking correct answer
        original_index = options.index(correct_answer_text)
        random.shuffle(options)
        new_correct_index = options.index(correct_answer_text) + 1
        
        # Rebuild exercise with randomized options
        formatted_options = "\n".join([f"# {i + 1}. {options[i]}" for i in range(len(options))])
        exercise = exercise.split("Options:")[0] + f"Options:\n{formatted_options}"
        
        # Update user's used sentences if authenticated
        if current_user.is_authenticated:
            current_app.mongo.db.users.update_one(
                {"_id": ObjectId(current_user.id)},
                {"$push": {"used_sentences": exercise}}
            )
        
        return {
            "exercise": exercise,
            "choices": options,
            "correct_answer": str(new_correct_index)
        }
    
    except Exception as e:
        return {
            "error": f"Error generating exercise: {str(e)}",
            "exercise": None,
            "choices": [],
            "correct_answer": None
        }
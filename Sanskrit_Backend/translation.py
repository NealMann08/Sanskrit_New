from flask import Flask, request, jsonify
from openai import OpenAI
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize OpenAI client with API key
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_translation_exercise(client, used_words=None):
    """
    Generates a Sanskrit translation exercise using OpenAI.
    
    Args:
        client: OpenAI client instance
        used_words: List of previously used Sanskrit words to avoid
    
    Returns:
        dict: Contains the exercise and correct answer
    """
    if used_words is None:
        used_words = []
    
    try:
        # Generate a new Sanskrit word
        used_words_str = ", ".join(used_words)
        word_completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher."},
                {
                    "role": "user",
                    "content": f"""Generate one Sanskrit word, its transliteration, and the English translation using one word.
The word should NOT be any of these previously used words: [{used_words_str}].
Print in this format: Word - Transliteration - Translation"""
                }
            ],
            temperature=1.2
        )
        
        # Get the word data
        word_data = word_completion.choices[0].message.content.strip()
        
        # Create the exercise
        exercise_completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher. Format your responses clearly."},
                {
                    "role": "user",
                    "content": f"""
Using this Sanskrit word data: {word_data}
Create an exercise in this format:
<EXERCISE>
Instructions: Translate this Sanskrit word into English.
Sanskrit Word: [Word] ([Transliteration])
</EXERCISE>
<ANSWER>
[Translation]
</ANSWER>
"""
                }
            ],
            temperature=0.7
        )
        
        # Parse the response
        exercise_response = exercise_completion.choices[0].message.content.strip()
        exercise = exercise_response.split('<EXERCISE>')[1].split('</EXERCISE>')[0].strip()
        answer = exercise_response.split('<ANSWER>')[1].split('</ANSWER>')[0].strip()
        
        # Add the new word to used words
        used_words.append(word_data)
        
        return {"exercise": exercise, "correct_answer": answer}
    
    except Exception as e:
        return {"error": f"Error generating translation exercise: {str(e)}"}
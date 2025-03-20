import openai
import random
from typing import Tuple, List, Optional

def generate_image(client: openai.OpenAI, word: str) -> Tuple[Optional[str], List[str], Optional[str]]:
    """
    Generates an educational image and multiple-choice question for Sanskrit learning.
    
    Args:
        client: OpenAI client instance
        word: The word to generate an image for
    
    Returns:
        Tuple containing:
        - image_url: URL of the generated image or None on error
        - options: List of Sanskrit word options
        - correct_answer: The correct Sanskrit word or None on error
    """
    try:
        # Generate educational image
        image_response = client.images.generate(
            model="dall-e-2",
            prompt=f"Generate a simple, clear educational illustration of {word} in a classroom style, white background, centered composition.",
            size="512x512",
            quality="standard",
            n=1
        )
        
        # Get image URL
        image_url = image_response.data[0].url
        
        # Generate Sanskrit options
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher."},
                {
                    "role": "user",
                    "content": f"""
                    Generate four Sanskrit words for {word}, mark the correct one with an asterisk (*).
                    Format each option as: 1. word
                    Make sure all options are grammatically correct Sanskrit words.
                    """
                }
            ],
            temperature=1.2
        )
        
        # Process the response
        response_text = completion.choices[0].message.content
        options = [line.strip() for line in response_text.split("\n") if line.strip()]
        options = [opt.split('. ')[1] for opt in options if '. ' in opt]
        
        # Find and clean the correct answer
        correct_answer = next(opt for opt in options if "*" in opt).replace("*", "")
        
        # Shuffle options while keeping track of correct answer
        original_index = options.index(correct_answer)
        random.shuffle(options)
        new_index = options.index(correct_answer)
        
        return image_url, options, correct_answer
    
    except Exception as e:
        return None, ["Error generating options"], f"Error: {str(e)}"
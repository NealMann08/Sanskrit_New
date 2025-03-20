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

def analyze_writing(image_base64, expected_sentence):
    """
    Analyzes Sanskrit writing in an image and compares it with expected text.
    
    Args:
        image_base64 (str): Base64 encoded image data
        expected_sentence (str): Expected Sanskrit sentence for comparison
    
    Returns:
        str: Analysis result or error message
    """
    try:
        # Verify inputs
        if not image_base64 or not expected_sentence:
            return "Missing required parameters: image_base64 and expected_sentence"
        
        # Create the prompt with proper formatting
        prompt = {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": f"""
                    Translate the Sanskrit sentence in the image to English.
                    If the sentence is similar to '{expected_sentence}', confirm it's correct.
                    Otherwise, state the errors.
                    """
                },
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
                }
            ]
        }
        
        # Make API request with error handling
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[prompt]
        )
        
        # Extract and clean the response
        result = response.choices[0].message.content.strip()
        return result
    
    except Exception as e:
        return f"Error analyzing writing: {str(e)}"

@app.route("/writing-analysis", methods=["POST"])
def writing_analysis_api():
    """
    API endpoint for Sanskrit writing analysis.
    
    Expects JSON payload:
    {
        "image_base64": "base64 encoded image data",
        "expected_sentence": "expected Sanskrit text"
    }
    
    Returns:
    {
        "analysis": "analysis result or error message"
    }
    """
    try:
        # Get request data
        data = request.json
        if not data:
            return jsonify({"error": "Invalid JSON payload"}), 400
        
        # Extract parameters
        image_base64 = data.get("image_base64")
        expected_sentence = data.get("expected_sentence")
        
        # Validate inputs
        if not image_base64 or not expected_sentence:
            return jsonify({"error": "Missing required parameters: image_base64 and expected_sentence"}), 400
        
        # Process the analysis
        result = analyze_writing(image_base64, expected_sentence)
        
        # Return the result
        return jsonify({"analysis": result})
    
    except Exception as e:
        return jsonify({"error": f"Error processing request: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(debug=True)
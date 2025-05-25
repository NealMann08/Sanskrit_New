from flask import Flask, request, jsonify, Response
from fill_in_the_blank import generate_fill_in_the_blank
from image_generation import generate_image
from writing_analysis import analyze_sanskrit_image, analyze_sanskrit_text
from translation import generate_translation_exercise  # Now safe to import
from flask_cors import CORS
from openai import OpenAI
import os
from dotenv import load_dotenv
from firebase_admin import auth
from functools import wraps
from firebase_utils import firestore_client
import logging


# Load environment variables
load_dotenv()


# Initialize Flask
app = Flask(__name__)
CORS(
    app,
    supports_credentials=True,
    origins=["http://localhost:*"],  # Allow all localhost ports
    methods=["GET", "POST"]
)
# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Initialize OpenAI
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


# Firebase Auth verification decorator
def firebase_authenticated(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Missing authorization token"}), 401
            
        try:
            token = auth_header.split('Bearer ')[1]
            decoded_token = auth.verify_id_token(token)
            request.uid = decoded_token['uid']  # Store UID in request object
        except ValueError as e:
            return jsonify({"error": "Invalid token format"}), 401
        except auth.InvalidIdTokenError:
            return jsonify({"error": "Invalid authentication token"}), 401
        except Exception as e:
            return jsonify({"error": f"Authentication failed: {str(e)}"}), 401
            
        return f(*args, **kwargs)
    return decorated_function
    
# Protected endpoints
@app.route('/fill-in-the-blank', methods=['GET'])
@firebase_authenticated
def fill_in_the_blank():
    try:
        result = generate_fill_in_the_blank(client=client, user_id=request.uid)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Endpoint error: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route('/generate-image', methods=['POST'])
@firebase_authenticated
def image_generation():
    try:
        data = request.get_json()
        prompt = data.get("prompt", "")
        image_url, options, correct_answer = generate_image(client, prompt, request.uid)
        return jsonify({
            "image_url": image_url,
            "options": options,
            "correct_answer": correct_answer
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/translation-exercise', methods=['GET'])
@firebase_authenticated
def translation_exercise():
    try:
        # Remove explicit firestore_client parameter
        exercise = generate_translation_exercise(
            client=client, 
            user_id=request.uid)
        return jsonify(exercise)
    except Exception as e:
        logger.error(f"Endpoint error: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# Text Analysis Endpoint
@app.route('/analyze-text', methods=['POST'])
def analyze_text():
    text = request.json.get('text')
    if not text:
        return jsonify({"error": "No text provided"}), 400
    
    analysis = analyze_sanskrit_text(text)  # Your text analysis function
    return jsonify({"analysis": analysis})

# Image Analysis Endpoint
@app.route('/analyze-image', methods=['POST'])
def analyze_image():
    image_base64 = request.json.get('image_base64')
    if not image_base64:
        return jsonify({"error": "No image provided"}), 400
    
    analysis = analyze_sanskrit_image(image_base64)  # Your image analysis function
    return jsonify({"analysis": analysis})

if __name__ == '__main__':
    app.run(debug=True)
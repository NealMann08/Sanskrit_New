from flask import Flask, request, jsonify, Response
import requests
from fill_in_the_blank import generate_fill_in_the_blank
from image_generation import generate_image
from writing_analysis import analyze_writing
from translation import generate_translation_exercise
from flask_pymongo import PyMongo
from flask_cors import CORS
import openai
import os
from dotenv import load_dotenv
from flask_login import (
    LoginManager, UserMixin, login_user,
    login_required, logout_user, current_user
)
import bcrypt
from bson.objectid import ObjectId

# Load environment variables
load_dotenv()

# Initialize Flask
app = Flask(__name__)
app.config["MONGO_URI"] = "mongodb://localhost:27017/sanskritlearning"
mongo = PyMongo(app)
CORS(app)

# Initialize OpenAI client with verification
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Verify the key was loaded
if not client.api_key:
    raise ValueError("OpenAI API key not found in environment variables")

# Set secret key
app.secret_key = os.getenv("SECRET_KEY", "REPLACE-ME")

# Initialize Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# Define the User class
class User(UserMixin):
    def __init__(self, user_doc):
        self.id = str(user_doc['_id'])
        self.username = user_doc['username']
        self.password = user_doc['password']
        self.used_words = user_doc.get('used_words', [])
        self.used_sentences = user_doc.get('used_sentences', [])

@login_manager.user_loader
def load_user(user_id):
    try:
        # Convert user_id to ObjectId and find the document
        user_doc = mongo.db.users.find_one({"_id": ObjectId(user_id)})
    except Exception as e:
        print("Error converting user_id:", e)
        return None
    if user_doc:
        return User(user_doc)
    return None

# Authentication Endpoints
@app.route('/signup', methods=['POST'])
def signup():
    """
    Expects JSON with "username" and "password".
    Example:
    {
        "username": "newuser",
        "password": "securepassword"
    }
    """
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400
    
    if mongo.db.users.find_one({"username": username}):
        return jsonify({"error": "Username already exists"}), 400
    
    # Generate a hashed password using bcrypt
    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    
    user_data = {
        "username": username,
        "password": hashed_password,
        "used_words": [],
        "used_sentences": []
    }
    
    inserted_user = mongo.db.users.insert_one(user_data)
    return jsonify({
        "message": "User registered successfully.",
        "user_id": str(inserted_user.inserted_id)
    }), 201

@app.route('/login', methods=['POST'])
def login():
    """
    Expects JSON with "username" and "password".
    Example:
    {
        "username": "testuser",
        "password": "password123"
    }
    """
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400

    user_data = mongo.db.users.find_one({"username": username})
    if user_data and bcrypt.check_password_hash(user_data["password"], password):
        user = User(user_data)
        login_user(user)
        return jsonify({"message": "Logged in successfully."}), 200
    else:
        return jsonify({"error": "Invalid credentials."}), 401

@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()
    return jsonify({"message": "Logged out successfully."}), 200

@app.route('/status', methods=['GET'])
def status():
    if current_user.is_authenticated:
        return jsonify({"logged_in": True, "username": current_user.username}), 200
    return jsonify({"logged_in": False}), 200

# Application Endpoints
@app.route('/')
def home():
    return "Sanskrit Learning API is Running!"

@app.route('/fill-in-the-blank', methods=['GET'])
@login_required
def fill_in_the_blank():
    result = generate_fill_in_the_blank(client)
    return jsonify(result)

@app.route('/generate-image', methods=['POST'])
@login_required
def image_generation():
    data = request.get_json()
    prompt = data.get("prompt", "")
    print(prompt)
    image_url, options, correct_answer = generate_image(client, prompt)
    return jsonify({
        "image_url": image_url,
        "options": options,
        "correct_answer": correct_answer
    })

@app.route('/writing-analysis', methods=['POST'])
@login_required
def writing_analysis():
    data = request.get_json()
    text = data.get("text", "")
    print(text)
    feedback = analyze_writing(text)
    print(feedback)
    return jsonify({"feedback": feedback})

@app.route('/translate', methods=['GET'])
@login_required
def translate():
    result = generate_translation_exercise(client)
    return jsonify(result)

@app.route('/proxy-image')
def proxy_image():
    image_url = request.args.get('url')
    if not image_url:
        return jsonify({"error": "Missing image URL"}), 400
    
    try:
        response = requests.get(image_url)
        if response.status_code != 200:
            return jsonify({
                "error": f"Failed to fetch image. Status code: {response.status_code}"
            }), response.status_code
        
        content_type = response.headers.get('Content-Type', 'application/octet-stream')
        return Response(response.content, headers={"Content-Type": content_type})
    
    except requests.exceptions.RequestException as e:
        error_message = f"Failed to fetch image: {str(e)}"
        return jsonify({"error": error_message}), 500

if __name__ == '__main__':
    app.run(debug=True)
# firebase_utils.py
import firebase_admin
from firebase_admin import credentials, firestore
import os
from pathlib import Path
import firebase_admin._auth_client
import firebase_admin._auth_utils
from google.auth import jwt
import logging

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get absolute path to credentials
current_dir = Path(__file__).parent
cred_path = current_dir / "config" / "firebase-service-account.json"

def initialize_firebase():
    try:
        if not firebase_admin._apps:
            if not cred_path.exists():
                raise FileNotFoundError(f"Service account file not found at {cred_path}")
            
            cred = credentials.Certificate(str(cred_path))
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {str(e)}")
        raise

# Initialize Firebase
initialize_firebase()

# Then get the firestore client
firestore_client = firestore.client()

def get_or_create_user(user_ref):
    """Transactionally get or create user document"""
    @firestore.transactional
    def transaction(transaction):
        doc = user_ref.get(transaction=transaction)
        if not doc.exists:
            transaction.set(user_ref, {
                "used_words": [],
                "translation_exercises": 0,
                "created_at": firestore.SERVER_TIMESTAMP,
                "last_active": firestore.SERVER_TIMESTAMP
            })
        return doc
    return transaction(firestore_client.transaction())
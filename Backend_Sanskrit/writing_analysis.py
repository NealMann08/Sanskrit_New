# import openai

# client = openai.OpenAI()

# def analyze_writing(text):
#     if not text:
#         return "No text provided for analysis."

#     prompt = f"Analyze the following Sanskrit text for grammar and style: {text}"

#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[{"role": "user", "content": prompt}]
#     )

#     feedback = response.choices[0].message.content
#     return feedback

from flask import Flask, request, jsonify
import base64
from openai import OpenAI

app = Flask(__name__)
client = OpenAI()

def analyze_writing(image_base64, expected_sentence):
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "user", "content": [
                    {"type": "text", "text": f"""
                    Translate the Sanskrit sentence in the image to English.
                    If the sentence is similar to '{expected_sentence}', confirm it's correct.
                    Otherwise, state the errors.
                    """},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
                ]}
            ]
        )
        result = response.choices[0].message.content.strip()
        return result
    except Exception as e:
        return str(e)

@app.route("/writing-analysis", methods=["POST"])
def writing_analysis_api():
    data = request.json
    image_base64 = data.get("image_base64")
    expected_sentence = data.get("expected_sentence")
    
    if not image_base64 or not expected_sentence:
        return jsonify({"error": "Missing image or expected sentence."}), 400
    
    result = analyze_writing(image_base64, expected_sentence)
    return jsonify({"analysis": result})

if __name__ == "__main__":
    app.run(debug=True)

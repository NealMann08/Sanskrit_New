import openai
import random

def generate_image(client, word):
    """Generates an image and multiple-choice question for Sanskrit learning."""
    try:
        response = client.images.generate(
            model="dall-e-2",
            prompt=f"Generate a simple image of {word} in a clear, educational style.",
            size="512x512",
            quality="standard",
            n=1
        )

        image_url = response.data[0].url

        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a Sanskrit teacher."},
                {"role": "user", "content": f"Generate four Sanskrit words for {word}, mark the correct one with an asterisk (*)."}
            ],
            temperature=1.2
        )

        response_text = completion.choices[0].message.content

        options = [line.strip() for line in response_text.split("\n") if line.strip()]
        options = [opt.split('. ')[1] for opt in options if '. ' in opt]
        correct_answer = next(opt for opt in options if "*" in opt).replace("*", "")

        random.shuffle(options)
        print(image_url, options, correct_answer)

        return image_url, options, correct_answer

    except Exception as e:
        return None, ["Error generating options"], f"Error: {e}"
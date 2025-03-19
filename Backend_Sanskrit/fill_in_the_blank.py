from openai import OpenAI
from flask import current_app
from flask_login import current_user
from bson.objectid import ObjectId
import random


def generate_fill_in_the_blank(client, used_sentences=[]):

    if current_user.is_authenticated:
        used_sentences = current_user.used_sentences
    used_sentence_str = ", ".join(used_sentences)


    
    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "You are a Sanskrit teacher."},
            {
                "role": "user",
                "content": f"""Generate one beginner-level fill-in-the-blank Sanskrit exercise.
                The exercise should not be any of the following sentences: [{used_sentence_str}].
                Do not provide the English translation at all.
                Use this structure and replace the [Verb] or [Object] with a blank:
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
    response = completion.choices[0].message.content

    completion_1 = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": "You are a Sanskrit teacher. Format responses cleanly."},
            {
                "role": "user",
                "content": f"""
                Use this Sanskrit fill-in-the-blank exercise: {response}
                
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
    response_1 = completion_1.choices[0].message.content
    
    exercise = response_1.split("<EXERCISE>")[1].split("</EXERCISE>")[0].strip()
    correct_answer = response_1.split("<ANSWER>")[1].split("</ANSWER>")[0].strip()
    
    correct_answer_num = response_1.split("<ANSWER>")[1].split("</ANSWER>")[0].strip()
    # Randomize options while maintaining correctness
    options = exercise.split("Options:")[1].strip().split("\n")
    options = [option.strip().split(". ", 1)[1] for option in options]
    correct_answer_text = options[int(correct_answer_num) - 1]  # Get the correct answer text
    random.shuffle(options)  # Shuffle options randomly
    correct_answer_new_index = options.index(correct_answer_text) + 1  # Find new index of correct answer

    # Rebuild exercise with randomized options
    randomized_options = "\n".join([f"# {i + 1}. {options[i]}" for i in range(len(options))])
    exercise = exercise.split("Options:")[0] + f"Options:\n{randomized_options}"
    
    
    used_sentences.append(exercise)
    #print({"exercise": exercise, "choices": options, "correct_answer": correct_answer})
    if current_user.is_authenticated:
        current_app.mongo.db.users.update_one(
            {"_id": ObjectId(current_user.id)},
            {"$push": {"used_sentences": exercise}}
        )

    
    return {"exercise": exercise, "choices": options, "correct_answer": correct_answer}


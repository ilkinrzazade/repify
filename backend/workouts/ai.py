"""
AI features with Google Gemini: gym equipment recognition (image understanding)
and the AI Coach chat.

The phone sends a photo to our server, the server asks Gemini what equipment
it shows and which exercises can be done with it. The API key stays on the
server, never inside the mobile app.

Configure the key with the environment variable GEMINI_API_KEY, or put it in
the file backend/ai_key.txt (that file is ignored by Git).
"""
import base64
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
# Tried in this order. If Google says a model is busy or unavailable,
# the next one is used. GEMINI_MODEL (if set) is always tried first.
FALLBACK_MODELS = [
    "gemini-3.5-flash-lite",
    "gemini-3.8-flash",
    "gemini-3.6-flash",
    "gemini-3.1-flash-lite",
]
# Status codes that mean "try another model": rate limit, overloaded, not found.
RETRY_STATUS = {404, 429, 500, 503}
KEY_FILE = Path(__file__).resolve().parent.parent / "ai_key.txt"

KNOWN_EQUIPMENT = [
    "Dumbbells", "Barbell", "Bench", "Cable Machine", "Lat Pulldown Machine",
    "Leg Press Machine", "Leg Extension / Curl Machine", "Pull-up Bar",
    "Dip Station", "Exercise Mat",
]

KNOWN_EXERCISES = [
    "Bench Press", "Incline Bench Press", "Dumbbell Bench Press", "Chest Fly",
    "Cable Crossover", "Push-up", "Dips", "Deadlift", "Pull-up", "Lat Pulldown",
    "Barbell Row", "Seated Cable Row", "Dumbbell Row", "Squat", "Leg Press",
    "Lunges", "Romanian Deadlift", "Leg Extension", "Leg Curl", "Calf Raise",
    "Overhead Press", "Dumbbell Shoulder Press", "Lateral Raise", "Rear Delt Fly",
    "Face Pull", "Biceps Curl", "Hammer Curl", "Preacher Curl", "Triceps Pushdown",
    "Skull Crusher", "Plank", "Crunch", "Hanging Leg Raise", "Russian Twist",
]

PROMPT = f"""You are a gym assistant. Look at the photo and identify the main piece of gym equipment.
Answer ONLY with JSON in this exact shape:
{{"equipment": "...", "confidence": 0.0, "muscles": ["..."], "exercises": ["..."], "tip": "..."}}
Rules:
- "equipment": prefer one of {KNOWN_EQUIPMENT}; otherwise a short English name.
- "confidence": a number from 0 to 1.
- "muscles": the main muscle groups trained, e.g. Chest, Back, Legs, Shoulders, Arms, Core.
- "exercises": 3 to 6 exercises that can be done with this equipment. Prefer names from {KNOWN_EXERCISES}.
- "tip": one short safety or technique tip (max 20 words).
- If the photo shows no gym equipment, use "equipment": "Unknown", confidence 0 and empty lists."""


class AiNotConfigured(Exception):
    """No API key on the server."""


class AiError(Exception):
    """The AI service failed or returned something unusable."""


def _api_key():
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not key and KEY_FILE.exists():
        key = KEY_FILE.read_text(encoding="utf-8").strip()
    return key


def _clean_list(value, limit):
    if not isinstance(value, list):
        return []
    items = [str(v).strip() for v in value if str(v).strip()]
    return items[:limit]


def parse_ai_answer(text):
    """Turns the model's JSON text into a safe, predictable dictionary."""
    text = text.strip()
    if text.startswith("```"):
        text = text.strip("`")
        text = text[text.find("{"):]
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise AiError("The AI answer was not valid JSON.") from exc
    if not isinstance(data, dict):
        raise AiError("Unexpected AI answer.")
    try:
        confidence = float(data.get("confidence", 0))
    except (TypeError, ValueError):
        confidence = 0.0
    return {
        "equipment": str(data.get("equipment") or "Unknown").strip(),
        "confidence": round(min(1.0, max(0.0, confidence)), 2),
        "muscles": _clean_list(data.get("muscles"), 6),
        "exercises": _clean_list(data.get("exercises"), 6),
        "tip": str(data.get("tip") or "").strip(),
    }


def _models_to_try():
    models = []
    preferred = os.environ.get("GEMINI_MODEL", "").strip()
    if preferred:
        models.append(preferred)
    for model in FALLBACK_MODELS:
        if model not in models:
            models.append(model)
    return models


def _call_model(model, body, key):
    """Returns the model's text answer, or raises urllib errors."""
    request = urllib.request.Request(
        GEMINI_URL.format(model=model),
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=25) as response:
        payload = json.loads(response.read().decode("utf-8"))
    try:
        parts = payload["candidates"][0]["content"]["parts"]
    except (KeyError, IndexError, TypeError) as exc:
        raise AiError("The AI service returned no answer.") from exc
    text = "".join(
        p.get("text", "") for p in parts if isinstance(p, dict) and not p.get("thought")
    )
    if not text.strip():
        raise AiError("The AI service returned no answer.")
    return text


def _generate(body):
    """Sends the request to Gemini, trying the next model when one is busy."""
    key = _api_key()
    if not key:
        raise AiNotConfigured("The AI service is not configured on the server.")

    for model in _models_to_try():
        try:
            return _call_model(model, body, key)
        except urllib.error.HTTPError as exc:
            if exc.code in RETRY_STATUS:
                continue  # busy or not available: try the next model
            if exc.code in (401, 403):
                raise AiError("The AI key is not valid. Check backend/ai_key.txt.") from exc
            raise AiError(f"The AI service rejected the request (error {exc.code}).") from exc
        except (urllib.error.URLError, TimeoutError):
            continue

    raise AiError("The AI service is busy right now. Please try again in a minute.")


def recognize_equipment(image_bytes, mime_type="image/jpeg"):
    body = {
        "contents": [{
            "parts": [
                {"inline_data": {
                    "mime_type": mime_type,
                    "data": base64.b64encode(image_bytes).decode("ascii"),
                }},
                {"text": PROMPT},
            ]
        }],
        "generationConfig": {"responseMimeType": "application/json", "temperature": 0.2},
    }
    return parse_ai_answer(_generate(body))


# ---------- AI Coach (chat) ----------

COACH_RULES = """You are Repify Coach, a friendly personal trainer inside the Repify gym tracker app.
Use the user's training data below to give specific, practical answers.
Rules:
- Reply in the language the user writes in.
- Keep it short: 2 to 6 sentences, or a short list with "-" bullets. Plain text, no tables or headings.
- Use kilograms. Refer to the user's real numbers (weights, dates, volume) when they help.
- Progressive overload: if the user did all reps at a weight, suggest +2.5 kg (upper body) or +5 kg (legs, deadlift).
- A muscle group needs about 48 hours to recover. Suggest groups that were not trained recently.
- Calories: estimate with MET values (strength training about 5 MET, circuit/HIIT about 8 MET).
  Body weight is unknown, so assume 75 kg and say it is an estimate.
- You are not a doctor. For pain, injuries or medical questions, recommend a professional.
- Only talk about training, recovery, nutrition basics and the app. Politely decline other topics.

USER DATA:
"""

MAX_CHAT_MESSAGES = 12
MAX_MESSAGE_CHARS = 2000


def chat_contents(messages):
    """
    Converts [{"role": "user"|"assistant", "text": "..."}] into Gemini "contents".
    Keeps the last messages only, merges repeated roles and starts with the user.
    """
    contents = []
    for message in messages[-MAX_CHAT_MESSAGES:]:
        role = "model" if message.get("role") == "assistant" else "user"
        text = str(message.get("text", "")).strip()[:MAX_MESSAGE_CHARS]
        if not text:
            continue
        if contents and contents[-1]["role"] == role:
            contents[-1]["parts"][0]["text"] += "\n" + text
        else:
            contents.append({"role": role, "parts": [{"text": text}]})
    while contents and contents[0]["role"] != "user":
        contents.pop(0)
    return contents


def coach_reply(messages, context):
    """Asks Gemini for the coach's next answer. `context` describes the user's data."""
    contents = chat_contents(messages)
    if not contents:
        raise AiError("Write a message first.")
    body = {
        "system_instruction": {"parts": [{"text": COACH_RULES + context}]},
        "contents": contents,
        "generationConfig": {"temperature": 0.6},
    }
    return _generate(body).strip()

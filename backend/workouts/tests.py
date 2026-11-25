from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .ai import AiError, AiNotConfigured, chat_contents, parse_ai_answer
from .coach import build_coach_context
from .models import Workout

User = get_user_model()

SAMPLE_WORKOUT = {
    "name": "Chest Day",
    "date": "2026-11-25T18:00:00Z",
    "durationSeconds": 2700,
    "exercises": [
        {"name": "Bench Press", "sets": "4", "reps": "8", "weight": "82.5"},
        {"name": "Chest Fly", "sets": 3, "reps": 12, "weight": 20},
    ],
}


class AuthTests(APITestCase):
    def test_register_returns_token(self):
        response = self.client.post(
            "/api/auth/register/",
            {"email": "Ilkin@Example.com", "password": "secret123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("token", response.data)
        self.assertEqual(response.data["email"], "ilkin@example.com")

    def test_register_duplicate_email_fails(self):
        User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        response = self.client.post(
            "/api/auth/register/",
            {"email": "ilkin@example.com", "password": "secret123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_short_password_fails(self):
        response = self.client.post(
            "/api/auth/register/",
            {"email": "a@example.com", "password": "123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_with_correct_password(self):
        User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        response = self.client.post(
            "/api/auth/login/",
            {"email": "ilkin@example.com", "password": "secret123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("token", response.data)

    def test_login_with_wrong_password_fails(self):
        User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        response = self.client.post(
            "/api/auth/login/",
            {"email": "ilkin@example.com", "password": "wrong"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_health_is_public(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)


class WorkoutApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        self.other = User.objects.create_user("other@example.com", "other@example.com", "secret123")
        token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

    def test_workouts_require_login(self):
        self.client.credentials()
        response = self.client.get("/api/workouts/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_create_and_list_workout(self):
        response = self.client.post("/api/workouts/", SAMPLE_WORKOUT, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["durationSeconds"], 2700)
        self.assertEqual(len(response.data["exercises"]), 2)
        self.assertEqual(response.data["exercises"][0]["name"], "Bench Press")
        self.assertEqual(response.data["exercises"][0]["weight"], 82.5)

        response = self.client.get("/api/workouts/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(Workout.objects.get().user, self.user)

    def test_workout_needs_at_least_one_exercise(self):
        data = dict(SAMPLE_WORKOUT, exercises=[])
        response = self.client.post("/api/workouts/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_user_sees_only_own_workouts(self):
        Workout.objects.create(user=self.other, name="Not mine", date="2026-11-20T18:00:00Z")
        self.client.post("/api/workouts/", SAMPLE_WORKOUT, format="json")
        response = self.client.get("/api/workouts/")
        self.assertEqual([w["name"] for w in response.data], ["Chest Day"])

    def test_delete_own_workout(self):
        workout_id = self.client.post("/api/workouts/", SAMPLE_WORKOUT, format="json").data["id"]
        response = self.client.delete(f"/api/workouts/{workout_id}/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Workout.objects.filter(id=workout_id).exists())

    def test_cannot_delete_other_users_workout(self):
        other_workout = Workout.objects.create(
            user=self.other, name="Not mine", date="2026-11-20T18:00:00Z"
        )
        response = self.client.delete(f"/api/workouts/{other_workout.id}/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Workout.objects.filter(id=other_workout.id).exists())

    def test_stats(self):
        self.client.post("/api/workouts/", SAMPLE_WORKOUT, format="json")
        response = self.client.get("/api/stats/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["workouts"], 1)
        self.assertEqual(response.data["exercises"], 2)
        # 4*8*82.5 + 3*12*20 = 2640 + 720
        self.assertEqual(response.data["totalVolume"], 3360)
        self.assertEqual(response.data["personalRecords"]["Bench Press"], 82.5)

    def test_logout_deletes_token(self):
        response = self.client.post("/api/auth/logout/")
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Token.objects.filter(user=self.user).exists())


class EquipmentRecognitionTests(APITestCase):
    """The AI service is replaced by a fake, so these tests need no internet."""

    def setUp(self):
        self.user = User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

    def _photo(self):
        return SimpleUploadedFile("machine.jpg", b"fake-image-bytes", content_type="image/jpeg")

    @patch("workouts.views.recognize_equipment")
    def test_recognize_returns_exercises(self, fake_ai):
        fake_ai.return_value = {
            "equipment": "Cable Machine",
            "confidence": 0.93,
            "muscles": ["Chest", "Arms"],
            "exercises": ["Cable Crossover", "Triceps Pushdown"],
            "tip": "Keep your elbows slightly bent.",
        }
        response = self.client.post(
            "/api/equipment/recognize/", {"image": self._photo()}, format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["equipment"], "Cable Machine")
        fake_ai.assert_called_once()

    def test_recognize_needs_a_photo(self):
        response = self.client.post("/api/equipment/recognize/", {}, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("workouts.views.recognize_equipment", side_effect=AiNotConfigured("not configured"))
    def test_recognize_without_api_key(self, fake_ai):
        response = self.client.post(
            "/api/equipment/recognize/", {"image": self._photo()}, format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_recognize_requires_login(self):
        self.client.credentials()
        response = self.client.post(
            "/api/equipment/recognize/", {"image": self._photo()}, format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class AiAnswerParsingTests(SimpleTestCase):
    def test_parses_and_cleans_the_answer(self):
        result = parse_ai_answer(
            '```json\n{"equipment": "Dumbbells", "confidence": 1.7, '
            '"muscles": ["Arms"], "exercises": ["Biceps Curl", "Hammer Curl"], "tip": "Go slow."}\n```'
        )
        self.assertEqual(result["equipment"], "Dumbbells")
        self.assertEqual(result["confidence"], 1.0)
        self.assertEqual(result["exercises"], ["Biceps Curl", "Hammer Curl"])

    def test_invalid_answer_raises(self):
        with self.assertRaises(AiError):
            parse_ai_answer("this is not json")


class CoachChatTests(APITestCase):
    """The AI is replaced by a fake: we check what the server sends to it."""

    def setUp(self):
        self.user = User.objects.create_user("ilkin@example.com", "ilkin@example.com", "secret123")
        token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

    def _chat(self, messages, **extra):
        return self.client.post("/api/coach/chat/", {"messages": messages, **extra}, format="json")

    @patch("workouts.views.coach_reply", return_value="Train legs today.")
    def test_chat_uses_my_workouts(self, fake_ai):
        self.client.post("/api/workouts/", SAMPLE_WORKOUT, format="json")
        response = self._chat([{"role": "user", "text": "What should I train today?"}])
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["reply"], "Train legs today.")
        messages, context = fake_ai.call_args.args
        self.assertEqual(messages[-1]["text"], "What should I train today?")
        self.assertIn("Chest Day", context)
        self.assertIn("Bench Press 4x8 @ 82.5 kg", context)

    @patch("workouts.views.coach_reply", return_value="Nice walk!")
    def test_health_data_is_added_to_context(self, fake_ai):
        response = self._chat(
            [{"role": "user", "text": "How active was I?"}],
            health={"steps": 6400, "heartRateAvg": 71.6},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        context = fake_ai.call_args.args[1]
        self.assertIn("steps: 6400", context)
        self.assertIn("average heart rate today (bpm): 72", context)

    def test_chat_requires_login(self):
        self.client.credentials()
        response = self._chat([{"role": "user", "text": "Hi"}])
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_chat_needs_a_message(self):
        response = self._chat([])
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_last_message_must_be_from_user(self):
        response = self._chat([{"role": "assistant", "text": "Hello!"}])
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("workouts.views.coach_reply", side_effect=AiNotConfigured("not configured"))
    def test_chat_without_api_key(self, fake_ai):
        response = self._chat([{"role": "user", "text": "Hi"}])
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_context_for_new_user(self):
        context = build_coach_context(self.user)
        self.assertIn("has not logged any workouts", context)


class ChatContentsTests(SimpleTestCase):
    def test_roles_are_converted_and_merged(self):
        contents = chat_contents([
            {"role": "assistant", "text": "Hi! I am your coach."},
            {"role": "user", "text": "Hello"},
            {"role": "user", "text": "What should I train?"},
            {"role": "assistant", "text": "Legs."},
        ])
        # The greeting is dropped: Gemini expects the user to speak first.
        self.assertEqual([c["role"] for c in contents], ["user", "model"])
        self.assertEqual(contents[0]["parts"][0]["text"], "Hello\nWhat should I train?")

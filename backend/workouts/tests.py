from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

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

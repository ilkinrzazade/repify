from rest_framework import mixins, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Workout
from .serializers import LoginSerializer, RegisterSerializer, WorkoutSerializer


def _auth_response(user, status_code=status.HTTP_200_OK):
    token, _ = Token.objects.get_or_create(user=user)
    return Response({"token": token.key, "email": user.email}, status=status_code)


@api_view(["GET"])
@permission_classes([AllowAny])
def health(request):
    """Used by the app to check that the server is reachable."""
    return Response({"status": "ok"})


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return _auth_response(user, status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return _auth_response(serializer.validated_data["user"])


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class WorkoutViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    """
    GET    /api/workouts/       list my workouts (newest first)
    POST   /api/workouts/       create a workout with its exercises
    GET    /api/workouts/<id>/  one workout
    DELETE /api/workouts/<id>/  delete a workout
    Each user only ever sees their own workouts.
    """

    serializer_class = WorkoutSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Workout.objects.filter(user=self.request.user).prefetch_related("exercises")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


@api_view(["GET"])
def stats(request):
    """Summary computed on the server: totals and personal records."""
    workouts = Workout.objects.filter(user=request.user).prefetch_related("exercises")
    records = {}
    exercise_count = 0
    total_volume = 0.0
    total_seconds = 0
    for workout in workouts:
        total_seconds += workout.duration_seconds
        for exercise in workout.exercises.all():
            exercise_count += 1
            total_volume += exercise.volume
            key = exercise.name.strip().lower()
            if exercise.weight > records.get(key, (None, -1))[1]:
                records[key] = (exercise.name.strip(), exercise.weight)
    return Response(
        {
            "workouts": len(workouts),
            "exercises": exercise_count,
            "totalVolume": round(total_volume),
            "totalMinutes": total_seconds // 60,
            "personalRecords": {name: weight for name, weight in records.values()},
        }
    )

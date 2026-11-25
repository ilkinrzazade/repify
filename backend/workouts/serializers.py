from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers

from .models import ExerciseEntry, Workout

User = get_user_model()


class ExerciseSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExerciseEntry
        fields = ["name", "sets", "reps", "weight"]


class WorkoutSerializer(serializers.ModelSerializer):
    """JSON format shared with the Flutter app (camelCase durationSeconds)."""

    durationSeconds = serializers.IntegerField(
        source="duration_seconds", min_value=0, default=0
    )
    exercises = ExerciseSerializer(many=True)

    class Meta:
        model = Workout
        fields = ["id", "name", "date", "durationSeconds", "exercises"]
        read_only_fields = ["id"]

    def validate_exercises(self, value):
        if not value:
            raise serializers.ValidationError("A workout needs at least one exercise.")
        return value

    def create(self, validated_data):
        exercises = validated_data.pop("exercises")
        workout = Workout.objects.create(**validated_data)
        ExerciseEntry.objects.bulk_create(
            [
                ExerciseEntry(workout=workout, order=index, **exercise)
                for index, exercise in enumerate(exercises)
            ]
        )
        return workout


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)

    def validate_email(self, value):
        value = value.strip().lower()
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data["email"],
            email=validated_data["email"],
            password=validated_data["password"],
        )


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(
            username=attrs["email"].strip().lower(),
            password=attrs["password"],
        )
        if user is None:
            raise serializers.ValidationError("Wrong email or password.")
        attrs["user"] = user
        return attrs

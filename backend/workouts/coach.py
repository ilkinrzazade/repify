"""
AI Coach: request validation and the summary of the user's data that is
given to the AI, so its answers are based on the user's real workouts.
"""
from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from .models import Workout

RECENT_WORKOUTS = 6
MAX_RECORDS = 10

# Health Connect values the phone may send, with a readable label.
HEALTH_FIELDS = {
    "steps": "steps",
    "activeCalories": "active kcal",
    "heartRateLatest": "latest heart rate (bpm)",
    "heartRateAvg": "average heart rate today (bpm)",
    "heartRateMax": "max heart rate today (bpm)",
}


class CoachMessageSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=["user", "assistant"])
    text = serializers.CharField(max_length=4000)


class CoachChatSerializer(serializers.Serializer):
    messages = CoachMessageSerializer(many=True, allow_empty=False)
    health = serializers.DictField(required=False, allow_null=True)

    def validate_messages(self, value):
        if value[-1]["role"] != "user":
            raise serializers.ValidationError("The last message must come from the user.")
        return value[-20:]


def _kg(value):
    return f"{value:g}"


def _health_line(health):
    parts = []
    for key, label in HEALTH_FIELDS.items():
        value = health.get(key)
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            continue
        parts.append(f"{label}: {round(value)}")
    return ", ".join(parts)


def build_coach_context(user, health=None, now=None):
    """Plain-text summary of the user's training for the AI."""
    now = now or timezone.now()
    today = timezone.localtime(now).date()
    workouts = list(
        Workout.objects.filter(user=user).prefetch_related("exercises")[:300]
    )  # newest first

    lines = [f"Today is {today:%A, %d %B %Y}."]
    if not workouts:
        lines.append("The user has not logged any workouts yet.")
    else:
        total_volume = sum(w.total_volume for w in workouts)
        total_minutes = sum(w.duration_seconds for w in workouts) // 60
        lines.append(
            f"Logged workouts: {len(workouts)}, total volume {round(total_volume)} kg, "
            f"total training time {total_minutes} min."
        )
        week = [w for w in workouts if w.date >= now - timedelta(days=7)]
        lines.append(
            f"Last 7 days: {len(week)} workouts, "
            f"{round(sum(w.total_volume for w in week))} kg, "
            f"{sum(w.duration_seconds for w in week) // 60} min."
        )

        lines.append("Recent workouts (newest first):")
        for workout in workouts[:RECENT_WORKOUTS]:
            days = (today - timezone.localtime(workout.date).date()).days
            when = "today" if days == 0 else ("yesterday" if days == 1 else f"{days} days ago")
            exercises = "; ".join(
                f"{e.name} {e.sets}x{e.reps} @ {_kg(e.weight)} kg" for e in workout.exercises.all()
            )
            lines.append(
                f"- {workout.name}, {when}, {workout.duration_seconds // 60} min: {exercises}"
            )

        # First, latest and best weight of every exercise (oldest workout first).
        progress = {}
        for workout in reversed(workouts):
            for e in workout.exercises.all():
                key = e.name.strip().lower()
                name, first, _, best = progress.get(key, (e.name.strip(), e.weight, e.weight, e.weight))
                progress[key] = (name, first, e.weight, max(best, e.weight))
        best_first = sorted(progress.values(), key=lambda item: item[3], reverse=True)
        lines.append("Exercise progress (first -> latest weight, personal record):")
        for name, first, latest, best in best_first[:MAX_RECORDS]:
            lines.append(f"- {name}: {_kg(first)} -> {_kg(latest)} kg, record {_kg(best)} kg")

    if isinstance(health, dict):
        line = _health_line(health)
        if line:
            lines.append(f"Today from Health Connect: {line}.")
    return "\n".join(lines)

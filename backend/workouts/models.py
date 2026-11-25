from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models


class Workout(models.Model):
    """One finished workout session of a user."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="workouts",
    )
    name = models.CharField(max_length=100)
    date = models.DateTimeField()
    duration_seconds = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date"]

    def __str__(self):
        return f"{self.name} ({self.date:%Y-%m-%d}) - {self.user}"

    @property
    def total_volume(self):
        """Total weight moved: sum of sets x reps x weight."""
        return sum(e.volume for e in self.exercises.all())


class ExerciseEntry(models.Model):
    """One exercise inside a workout, e.g. Bench Press 4 x 8 @ 80 kg."""

    workout = models.ForeignKey(
        Workout,
        on_delete=models.CASCADE,
        related_name="exercises",
    )
    name = models.CharField(max_length=100)
    sets = models.PositiveIntegerField()
    reps = models.PositiveIntegerField()
    weight = models.FloatField(validators=[MinValueValidator(0)])
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "id"]
        verbose_name_plural = "exercise entries"

    def __str__(self):
        return f"{self.name} {self.sets}x{self.reps} @ {self.weight} kg"

    @property
    def volume(self):
        return self.sets * self.reps * self.weight

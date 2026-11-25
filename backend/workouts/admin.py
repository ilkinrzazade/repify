from django.contrib import admin

from .models import ExerciseEntry, Workout


class ExerciseEntryInline(admin.TabularInline):
    model = ExerciseEntry
    extra = 0
    fields = ["order", "name", "sets", "reps", "weight"]


@admin.register(Workout)
class WorkoutAdmin(admin.ModelAdmin):
    list_display = ["name", "user", "date", "duration_minutes", "exercise_count", "volume_kg"]
    list_filter = ["user", "name"]
    search_fields = ["name", "user__email", "exercises__name"]
    date_hierarchy = "date"
    inlines = [ExerciseEntryInline]

    @admin.display(description="Minutes")
    def duration_minutes(self, obj):
        return obj.duration_seconds // 60

    @admin.display(description="Exercises")
    def exercise_count(self, obj):
        return obj.exercises.count()

    @admin.display(description="Volume (kg)")
    def volume_kg(self, obj):
        return round(obj.total_volume)


@admin.register(ExerciseEntry)
class ExerciseEntryAdmin(admin.ModelAdmin):
    list_display = ["name", "sets", "reps", "weight", "workout"]
    search_fields = ["name"]

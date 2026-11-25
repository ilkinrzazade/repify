from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from workouts.models import ExerciseEntry, Workout

DEMO_EMAIL = "demo@repify.app"
DEMO_PASSWORD = "demo1234"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin12345"


class Command(BaseCommand):
    help = "Creates a demo user with six weeks of sample workouts and an admin account (development only)."

    def handle(self, *args, **options):
        User = get_user_model()

        if not User.objects.filter(username=ADMIN_USERNAME).exists():
            User.objects.create_superuser(ADMIN_USERNAME, "admin@repify.app", ADMIN_PASSWORD)
            self.stdout.write(f"Admin created: {ADMIN_USERNAME} / {ADMIN_PASSWORD}")

        user, created = User.objects.get_or_create(
            username=DEMO_EMAIL, defaults={"email": DEMO_EMAIL}
        )
        user.set_password(DEMO_PASSWORD)
        user.save()
        Workout.objects.filter(user=user).delete()

        today = timezone.localtime().replace(hour=18, minute=0, second=0, microsecond=0)

        def days_ago(days):
            return today - timedelta(days=days)

        bench = [60, 65, 70, 72.5, 77.5, 82.5]
        squat = [80, 85, 90, 95, 100, 105]
        deadlift = [100, 105, 112.5, 117.5, 122.5, 127.5]

        plans = []
        for week in range(6):
            offset = 7 * week
            plans.append(("Push Day", days_ago(40 - offset), 50 + week, [
                ("Bench Press", 4, 8, bench[week]),
                ("Overhead Press", 3, 10, 35 + 2.5 * week),
                ("Triceps Pushdown", 3, 12, 25),
            ]))
            plans.append(("Leg Day", days_ago(38 - offset), 58 + week, [
                ("Squat", 4, 8, squat[week]),
                ("Leg Press", 3, 12, 160 + 10 * week),
                ("Leg Curl", 3, 12, 40),
            ]))
            plans.append(("Pull Day", days_ago(36 - offset), 62 + week, [
                ("Deadlift", 3, 5, deadlift[week]),
                ("Lat Pulldown", 3, 10, 50 + 2.5 * week),
                ("Barbell Row", 3, 10, 60 + 2.5 * week),
            ]))

        for name, date, minutes, exercises in plans:
            workout = Workout.objects.create(
                user=user, name=name, date=date, duration_seconds=minutes * 60
            )
            ExerciseEntry.objects.bulk_create([
                ExerciseEntry(workout=workout, order=i, name=n, sets=s, reps=r, weight=w)
                for i, (n, s, r, w) in enumerate(exercises)
            ])

        self.stdout.write(self.style.SUCCESS(
            f"Demo user ready: {DEMO_EMAIL} / {DEMO_PASSWORD} ({len(plans)} workouts)"
        ))

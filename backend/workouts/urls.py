from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("workouts", views.WorkoutViewSet, basename="workout")

urlpatterns = [
    path("health/", views.health, name="health"),
    path("auth/register/", views.RegisterView.as_view(), name="register"),
    path("auth/login/", views.LoginView.as_view(), name="login"),
    path("auth/logout/", views.LogoutView.as_view(), name="logout"),
    path("stats/", views.stats, name="stats"),
    path("equipment/recognize/", views.EquipmentRecognizeView.as_view(), name="equipment-recognize"),
    path("coach/chat/", views.CoachChatView.as_view(), name="coach-chat"),
    path("", include(router.urls)),
]

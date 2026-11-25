# Repify backend

REST API for the Repify mobile app, built with Django and Django REST Framework.
Data is stored in SQLite (`db.sqlite3`), a real SQL database in a single file.

## Run it

Requires Python 3.10 or newer.

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows  (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
python manage.py makemigrations workouts
python manage.py migrate
python manage.py seed_demo     # demo user + sample data + admin account
python manage.py runserver 0.0.0.0:8000
```

- Demo user (log in from the app): `demo@repify.app` / `demo1234`
- Admin panel: http://127.0.0.1:8000/admin/ with `admin` / `admin12345`
- Android emulator reaches the server at `http://10.0.2.2:8000`
- A real phone on the same Wi-Fi uses `http://<laptop IP>:8000` (set it in the app's Settings)

## Tests

```bash
python manage.py test
```

## API

All endpoints except health, register and login need the header
`Authorization: Token <token>`.

| Method | URL | Description |
|---|---|---|
| GET | `/api/health/` | Server check |
| POST | `/api/auth/register/` | `{email, password}` → `{token, email}` |
| POST | `/api/auth/login/` | `{email, password}` → `{token, email}` |
| POST | `/api/auth/logout/` | Deletes the token |
| GET | `/api/workouts/` | My workouts, newest first |
| POST | `/api/workouts/` | Create a workout with its exercises |
| GET | `/api/workouts/<id>/` | One workout |
| DELETE | `/api/workouts/<id>/` | Delete a workout |
| GET | `/api/stats/` | Totals and personal records |

Workout JSON:

```json
{
  "id": 7,
  "name": "Chest Day",
  "date": "2026-11-25T18:00:00+02:00",
  "durationSeconds": 2700,
  "exercises": [
    {"name": "Bench Press", "sets": 4, "reps": 8, "weight": 82.5}
  ]
}
```

These settings are for development only (DEBUG on, all hosts allowed).

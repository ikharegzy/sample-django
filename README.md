# Task 2 — Implementing Docker Compose for Local Development

This repository is ready for local work thanks to **Docker Compose**.

`docker-compose.yml` starts two services:

* **db** — lightweight `postgres:17-alpine` initialised with the credentials from `.env`  
* **web** — the Django app built from the Dockerfile at the project root

At launch the entry-point script waits for Postgres, runs migrations, *optionally* creates an admin user and finally starts Gunicorn on **port 8000**.



## Why Compose is useful

Running both services through Compose removes “works-on-my-machine” issues.  
Everyone on the team gets identical Python, Django and Postgres versions, the same environment variables and predictable network names.  
No local Postgres install, no virtual-env rebuilds, no remembering Gunicorn flags.  
One command brings the stack up; another tears it down and keeps your workstation clean.

---

## One-time preparation

1. Install and run Docker Desktop (or Docker Engine + Compose CLI).  
2. Copy `.env.example` → `.env` and fill **three** variables:

```env
POSTGRES_DB=django
POSTGRES_USER=postgres
POSTGRES_PASSWORD=choose-a-strong-password
```

These values feed both the database container and Django’s DATABASE_URL.
The first build can take a minute while images download and Python wheels cache.

## Daily workflow

Start or rebuild everything:

```docker compose --env-file .env up --build```

Compose reads .env, builds the image if needed, waits for Postgres to become healthy and then starts Django.
The site is now reachable at http://localhost:8000.
Logs from both containers stream to the terminal; stop them any time with Ctrl-C.
After code changes just rerun the same command — layer caching keeps rebuilds fast.
Shut the stack down when you’re done:

```
docker compose down       # leaves the postgres_data volume intact
# need a completely fresh database?
docker compose down -v       # also removes the volume
```

## What teammates need to do

```
git clone <repo>
cp .env.example .env   # edit three variables
docker compose up --build
# hack away…
docker compose down    # and you’re finished
```

That’s it — no other host software required.
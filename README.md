# Task 2 — Implementing Docker Compose for Local Development

This repository is ready for out-of-the-box local development thanks to Docker Compose.
The compose file (docker-compose.yml) describes two services:

db – a lightweight postgres:17-alpine container that initialises with the credentials you place in .env.
web – a Django application built from the Dockerfile in the project root.
At start-up the entry-point script waits for Postgres, runs all migrations, optionally creates an admin user and then launches Gunicorn on port 8000.
Why Compose is helpful

Running both services through Compose removes host-to-host inconsistencies: everyone on the team gets the same Python, Django and Postgres versions, the same environment variables and the same network names. You no longer need to install or configure Postgres locally, rebuild virtual-envs or remember how to start Gunicorn. One command spins the whole stack up, another tears it down, keeping your workstation clean.

One-time preparation

Make sure Docker Desktop (or Docker Engine + Compose CLI) is installed and running.
Copy .env.example to .env and fill in three variables:

POSTGRES_DB=django
POSTGRES_USER=postgres
POSTGRES_PASSWORD=choose-a-strong-password

These values feed both the database container and Django’s DATABASE_URL.
No other software is required on the host. The first build may take a minute while images are downloaded and Python wheels are cached.

Daily workflow for any teammate

Open a terminal in the repository root and type:

docker compose --env-file .env up --build

Compose reads the variables from .env, builds the application image if it is not cached, brings db online and, once Postgres is healthy, starts the Django service.
– The site is now reachable at http://localhost:8000.
– Logs from both containers stream to the terminal; stop them at any moment with Ctrl-C.
– To rebuild after code changes just rerun the same command. Docker layer caching keeps rebuilds fast.
– When you finish, tidy everything with:

docker compose down
This command stops containers and removes the dedicated network while leaving your database volume (postgres_data) intact.
If you need a completely fresh database, add the -v flag: docker compose down -v.

That is all your teammates need: clone the repo, edit .env, run docker compose up --build, code as usual and shut the stack down when done.
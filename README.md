# Callagent - A project at the Hackerton Kassel 2026
Callagent is an ai agent for olderly person which need help in their houshold using their conventional phone and a phonecall with speach.
An internal monitoring via the frontend is for administration.


## Installation guide
The project has an architecture depending on code of bot and frontend and external services. Install this folder bot and frontend.


## Running with Docker

### Prerequisites
- Install Docker Desktop: https://www.docker.com/products/docker-desktop

### Start API + Bot (recommended)
```bash
cp .env.example .env
docker compose up --build
```

**Access:**
- API: http://localhost:5000
- API health: http://localhost:5000/health
- Bot (Pipecat runner): http://localhost:7860

For detailed Docker documentation, troubleshooting, and production setup, see [DOCKER.md](DOCKER.md).

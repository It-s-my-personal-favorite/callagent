import os
from pathlib import Path


def _load_dotenv() -> None:
	"""Load key/value pairs from a local .env file into os.environ."""
	dotenv_path = Path(__file__).resolve().parent / ".env"
	if not dotenv_path.exists():
		return

	for raw_line in dotenv_path.read_text(encoding="utf-8").splitlines():
		line = raw_line.strip()
		if not line or line.startswith("#") or "=" not in line:
			continue

		key, value = line.split("=", 1)
		key = key.strip()
		value = value.strip().strip('"').strip("'")
		os.environ.setdefault(key, value)


_load_dotenv()


def _required_env(name: str) -> str:
	value = os.getenv(name)
	if value is None or value == "":
		raise RuntimeError(f"Missing required environment variable: {name}")
	return value


class Config:
	FLASK_ENV = _required_env("FLASK_ENV")
	SECRET_KEY = _required_env("SECRET_KEY")

	PG_HOST = _required_env("PG_HOST")
	PG_PORT = int(_required_env("PG_PORT"))
	PG_USER = _required_env("PG_USER")
	PG_PASSWORD = _required_env("PG_PASSWORD")
	PG_DATABASE = _required_env("PG_DATABASE")
	PG_ADMIN_DATABASE = _required_env("PG_ADMIN_DATABASE")

	SQLALCHEMY_DATABASE_URI = (
		f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"
	)
	SQLALCHEMY_TRACK_MODIFICATIONS = False
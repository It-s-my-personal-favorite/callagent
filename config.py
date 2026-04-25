import os


class Config:
	FLASK_ENV = os.getenv("FLASK_ENV", "development")
	SECRET_KEY = os.getenv("SECRET_KEY", "change-this-secret-key")

	PG_HOST = os.getenv("PG_HOST", "localhost")
	PG_PORT = int(os.getenv("PG_PORT", "5432"))
	PG_USER = os.getenv("PG_USER", "postgres")
	PG_PASSWORD = os.getenv("PG_PASSWORD", "postgres")
	PG_DATABASE = os.getenv("PG_DATABASE", "callagent")
	PG_ADMIN_DATABASE = os.getenv("PG_ADMIN_DATABASE", "postgres")

	SQLALCHEMY_DATABASE_URI = (
		f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"
	)
	SQLALCHEMY_TRACK_MODIFICATIONS = False
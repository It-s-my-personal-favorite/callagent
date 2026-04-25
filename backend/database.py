import psycopg2
from psycopg2 import sql

from config import Config


def ensure_database_exists() -> None:
    connection = psycopg2.connect(
        dbname=Config.PG_ADMIN_DATABASE,
        user=Config.PG_USER,
        password=Config.PG_PASSWORD,
        host=Config.PG_HOST,
        port=Config.PG_PORT,
    )
    connection.autocommit = True

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s",
                (Config.PG_DATABASE,),
            )
            exists = cursor.fetchone() is not None

            if not exists:
                cursor.execute(
                    sql.SQL("CREATE DATABASE {};").format(
                        sql.Identifier(Config.PG_DATABASE)
                    )
                )
    finally:
        connection.close()

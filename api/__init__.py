def create_app():
	# Avoid importing backend.app at package import time; this prevents
	# runpy warnings when running `python -m backend.app`.
	from api.app import create_app as _create_app

	return _create_app()


__all__ = ["create_app"]

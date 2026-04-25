def create_app():
	# Avoid importing api.app at package import time; this prevents
	# runpy warnings when running `python -m api.app`.
	from api.app import create_app as _create_app

	return _create_app()


__all__ = ["create_app"]

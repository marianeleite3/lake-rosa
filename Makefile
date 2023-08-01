.PHONY: prepare-env
prepare-env:
	$(PYTHON_SETUP) -m venv .env
	( \
		. $(PYTHON_BIN)/activate; \
		 python -m ensurepip --default-pip; \
 		 pip install poetry; \
		 poetry install --no-root --with dev; \
		 pre-commit install; \
	)
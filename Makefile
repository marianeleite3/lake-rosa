########## TEXT ##########
BOLD = \033[1m
BLACK = \033[0;30m
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
WHITE = \033[0;37m
####### BACKGROUND #######
RED_BG = \033[41m
GREEN_BG = \033[42m
YELLOW_BG = \033[43m
####### RESET BG #######
NC = \033[0m

################
# OS DETECTION #
################

ifeq ($(OS),Windows_NT)     # is Windows_NT on XP, 2000, 7, Vista, 10...
    DETECTED_OS := Windows
else
    DETECTED_OS := $(shell uname)  # same as "uname -s"
endif

#########
# Tasks #
#########

.PHONY: checks
checks: code-style-check quality-check-diff safety-check ## - [Run all checks]

.PHONY: code-style-check
code-style-check: check/code-style ## - [Check code style with black]
check/code-style:
	$(PYTHON_BIN)/black --check -t py37 --exclude="examples/|\alembic/|\.github/|\.git/|\.pytest_cache/|\.mypy_cache/|\.env/" .

.PHONY: quality-check
quality-check: check/quality ## - [Check code quality with flake8]
check/quality:
	$(PYTHON_BIN)/flake8

.PHONY: quality-check-diff
quality-check-diff: check/quality/diff ## - [Check code quality with flake8]
check/quality/diff:
	git diff --staged | $(PYTHON_BIN)/flake8 --diff

.PHONY: safety-check
safety-check: safety/quality ## - [Check your installed dependencies for known security vulnerabilities with safety]
safety/quality:
		# netskope compability: https://docs.netskope.com/en/configuring-cli-based-tools-and-development-frameworks-to-work-with-netskope-ssl-interception.html
		# export REQUESTS_CA_BUNDLE=/c/ProgramData/netskope/stagent/data/nscacert.pem
		# or pip install pip-system-certs
		$(PYTHON_BIN)/safety check --ignore=51668 --ignore=42194 --ignore=58982


.PHONY: fix-style
fix-style: fix/style ## - [Fix style guides with black and isort]
fix/style:
	$(PYTHON_BIN)/isort src/ test/
	$(PYTHON_BIN)/black -t py37 --color src/ test/ --exclude="examples/|\alembic/|\.github/|\.git/|\.pytest_cache/|\.mypy_cache/|\.env/" .


.PHONY: test
test: dependencies-services test/run dependencies/clean/services ## - [All-in-one command to start requirements, compile and test the application]
test/run:
	( \
		. $(PYTHON_BIN)/activate; \
		py.test test/src; \
	)


.PHONY: integration-test
integration-test: dependencies-services integration-test/run dependencies/clean/services ## - [All-in-one command to start requirements, compile and test the application]
integration-test/run:
	( \
		. $(PYTHON_BIN)/activate; \
		py.test test/integration; \
	)


.PHONY: dependencies-services
dependencies-services: dependencies/services/run db-migrate ## - [Setup the local development environment with python3 venv and project dependencies]
dependencies/services/run:
	docker-compose up -d
	docker-compose run wait
dependencies/clean/services:
	docker-compose stop && docker-compose rm -fsv

.PHONY: db-migration
db-migration: db/migration  ## - [Generate a new migration file that holds a database change. E.g: make db/migration name=your_migration_name]
db/migration:
	( \
		. $(PYTHON_BIN)/activate; \
		alembic revision -m $(name); \
	)

.PHONY: db-migrate
db-migrate: ## - [Run the pending migrations against the local database]
	( \
		. $(PYTHON_BIN)/activate; \
		alembic -x DB_URL=$(MIGRATE_DB_URL) upgrade head; \
	)

.PHONY: db-migrate-down
db-migrate-down: ## - [Run the pending migrations against the local database]
	( \
		. $(PYTHON_BIN)/activate; \
		alembic -x DB_URL=$(MIGRATE_DB_URL) downgrade -1; \
	)

.PHONY: db-migrate-up
db-migrate-up: ## - [Run the pending migrations against the local database]
	( \
		. $(PYTHON_BIN)/activate; \
		alembic -x DB_URL=$(MIGRATE_DB_URL) upgrade +1; \
	)

.PHONY: db-migrate-nonprod-prod
db-migrate-nonprod-prod: ## - [Run the pending migrations against the configured databases (prod and nonprod)]
	( \
		. $(PYTHON_BIN)/activate; \
		alembic -x DB_URL=$(MIGRATE_DB_URL_PROD) upgrade head; \
		alembic -x DB_URL=$(MIGRATE_DB_URL_NONPROD) upgrade head; \
	)

.PHONY: dev-setup
dev-setup: ## - [Setup the local development environment with python3 venv and project dependencies]
	# TODO Include conditional argument to detect when working with Linux

	# ifeq (${shell uname -s}, Linux)
	# 	sudo apt-get update
	# 	sudo apt-get install libpq-dev python3-dev python3-venv openjdk-8-jre
	# endif

	$(PYTHON_SETUP) -m venv .env
	( \
		. $(PYTHON_BIN)/activate; \
		 python -m ensurepip --default-pip; \
 		 pip install poetry; \
		 poetry install --no-root --with dev; \
		 pre-commit install; \
	)


.PHONY: deploy-release
deploy-release: ## - [Setup to deploy new releases]
	$(PYTHON_SETUP) -m venv .env
	( \
		. $(PYTHON_BIN)/activate; \
		python -m ensurepip --default-pip; \
 		pip install poetry; \
        poetry install --only release; \
		git fetch --all --tags; \
		git tag --list; \
		cz bump --annotated-tag --changelog --check-consistency; \
		git remote set-url origin https://SRV-IRISGITHUB:$(GITHUB_TOKEN)@github.com/cervejaria-ambev/pyiris.git; \
		git push --tags origin HEAD:master; \
		poetry config repositories.nexus $(NEXUS_URL); \
		poetry config http-basic.nexus $(NEXUS_USERNAME) $(NEXUS_PASSWORD); \
		poetry config repositories.azure $(AZURE_ARTIFACTS_URL); \
		poetry config http-basic.azure $(if $(AZURE_ARTIFACTS_USERNAME), $(AZURE_ARTIFACTS_USERNAME), '__token__') $(if $(AZURE_ARTIFACTS_PASSWORD), $(AZURE_ARTIFACTS_PASSWORD), $(SYSTEM_ACCESSTOKEN)); \
		poetry build; \
		$(if $(NEXUS_URL), \
			poetry publish -r nexus --skip-existing, \
			echo "Nexus not configured (Needs NEXUS_URL, NEXUS_USERNAME and NEXUS_PASSWORD)"); \
		$(if $(AZURE_ARTIFACTS_URL), \
			poetry publish -r azure --skip-existing, \
			echo "Azure artifacts not configured (Needs AZURE_ARTIFACTS_URL, AZURE_ARTIFACTS_USERNAME and AZURE_ARTIFACTS_PASSWORD)"); \
	)


# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
.PHONY: help
help:
	@echo $(ECHO_ARGS) "$(BLACK)$(BOLD)$(GREEN_BG)Available Tasks:$(NC)$(NC)$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-5s\033[0m %s\n", $$1, $$2}'


###############
# Definitions #
###############
export ANSICON=1 # Colors for Windows

ifeq ($(DETECTED_OS),Windows)
	PYTHON_BIN ?= .env/Scripts
	ECHO_ARGS ?= '-e'
	PYTHON_SETUP ?= 'python'
else
	PYTHON_BIN ?= .env/bin
	ECHO_ARGS ?= ''
	PYTHON_SETUP ?= 'python3'
endif

DB_PORT ?= 5432
DB_NAME ?= iris
DB_USER ?= postgres
DB_PASSWORD ?= postgres
DB_HOST ?= localhost

TEST_MIGRATE_DB_URL := postgresql://postgres:postgres@localhost:5432/iris
MIGRATE_DB_URL := postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)

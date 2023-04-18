.PHONY: test help clean
.DEFAULT_GOAL := help

# Global Variables
CURRENT_PWD:=$(shell pwd)
VENV_DIR:=.env
AWS_PROFILE:=elf

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy ALL stack
	sh deploy.sh

destroy: ## Delete Stack without confirmation
	az group delete --name dataGeneratorSwarm01

clean: ## Remove All virtualenvs
	@rm -rf ${PWD}/${VENV_DIR} build dist *.egg-info .eggs .pytest_cache .coverage
	@find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf

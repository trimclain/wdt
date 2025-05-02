SHELL := /bin/bash

all:
	@echo 'Type "make help" to see the help menu.'

help: ## Print this help menu
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# TODO:
install: ## Install wdt
	@if [[ ! -d $$HOME/.local/bin ]]; then mkdir -p $$HOME/.local/bin && \
		echo 'Created ~/.local/bin. Please add it to $$PATH and run "make install" again.'; \
		elif [[ ! :$$PATH: == *":$$HOME/.local/bin:"* ]]; \
		then echo 'Please add ~/.local/bin to $$PATH.'; \
		else cp ./src/wdt $$HOME/.local/bin/ && echo "WDT installed successfully."; \
		fi

uninstall: ## Uninstall wdt
	@if [[ -f $$HOME/.local/bin/wdt ]]; then rm $$HOME/.local/bin/wdt && \
		echo "WDT uninstalled successfully."; else echo "WDT not found."; fi

container: ## Build a docker container for testing
	@if ! command -v docker > /dev/null; then echo "Docker not found, install it first"; \
		elif [[ $$(docker images | grep wdttest) ]]; then \
		echo 'Container "wdttest" already exists'; else echo 'Building the "wdttest" container' \
		&& docker build -t wdttest . && echo "Built successfully"; fi

delcontainer:
	@if [[ $$(docker images | grep wdttest) ]]; then echo 'Deleting "wdttest" container' && \
		docker image rm wdttest:latest -f; \
		else echo 'Container "wdttest" not found. Build it with \`make container\`.'; fi

rebuild: delcontainer container ## Rebuild existing docker container

test: ## Run tests
	./test/bats/bin/bats test/test.bats

# test: ## Run the wdttest container
# 	@if [[ $$(docker images | grep wdttest) ]]; then docker run -it wdttest; \
# 		else echo 'Container "wdttest" not found. Build it with \`make container\`.'; fi


.PHONY: all help install uninstall container delcontainer rebuild test

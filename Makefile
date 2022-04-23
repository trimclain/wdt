SHELL := /bin/bash

all:
	@echo 'Type "make help" to see the help menu.'

help: ## Prints this help menu
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Installs wdt
	@if [[ ! -d $$HOME/.local/bin ]]; then mkdir -p $$HOME/.local/bin && \
		echo 'Created ~/.local/bin. Please add it to $$PATH'; \
		else if [[ ! :$$PATH: == *":$$HOME/.local/bin:"* ]]; \
		then echo 'Please add ~/.local/bin to $$PATH.'; \
		else cp ./wdt $$HOME/.local/bin/ && echo "WDT installed successfully."; \
		fi; fi

uninstall: ## Uninstalls wdt
	@if [[ -f $$HOME/.local/bin/wdt ]]; then rm $$HOME/.local/bin/wdt && \
		echo "WDT uninstalled successfully."; else echo "WDT not found."; fi

.PHONY: all help install uninstall

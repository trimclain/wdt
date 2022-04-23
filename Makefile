SHELL := /bin/bash

all:
	@echo 'Type "make help" to see the help menu.'

help: ## Prints this help menu
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Installs wdt
	@if [[ ! :$$PATH: == *":$$HOME/.local/bin:"* ]]; \
		then echo 'Please add ~/.local/bin to $$PATH.' && echo *":$$HOME/.local/bin:"*; \
		else cp ./wdt $$HOME/.local/bin/ && echo "WDT installed successfully."; \
		fi

uninstall: ## Uninstalls wdt
	@if [[ -f $$HOME/.local/bin/wdt ]]; then rm $$HOME/.local/bin/wdt && \
		echo "WDT uninstalled successfully."; else echo "WDT not found."; fi

.PHONY: all help install uninstall

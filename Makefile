SHELL := /bin/bash

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-43s\033[0m %s\n", $$1, $$2}' \
	| sed -e 's/\[32m #-- /[33m/'

#-- Ubuntu
ubuntu-2004: ## Run Ubuntu 20.04
	docker run -it -v $(PWD):/host ubuntu:20.04


ubuntu-2204: ## Run Ubuntu 22.04
	docker run -it -v $(PWD):/host ubuntu:22.04

ubuntu-2404: ## Run Ubuntu 24.04
	docker run -it -v $(PWD):/host ubuntu:24.04


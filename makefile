#
# Makefile
#

.PHONY: help
.DEFAULT_GOAL := help

MOD_NAME="nicefill-scriptfix"
MOD_VERSION=`jq -r .version $(MOD_NAME)/info.json`

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ------------------------------------------------------------------------------------------------------------

zip: ## Creates a new ZIP package
	@cd .. && echo "Creating Zip file $(MOD_NAME)_$(MOD_VERSION).zip\n"
	@cd .. && rm -rf $(MOD_NAME)_$(MOD_VERSION).zip
	@cd .. && zip -qq -r -0 $(MOD_NAME)_$(MOD_VERSION).zip $(MOD_NAME)/ -x@$(MOD_NAME)/zip.exclude.lst

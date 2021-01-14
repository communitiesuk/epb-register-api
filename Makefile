.DEFAULT_GOAL := help
SHELL := /bin/bash

PAAS_API ?= api.london.cloud.service.gov.uk
PAAS_ORG ?= mhclg-energy-performance
PAAS_SPACE ?= ${STAGE}

define check_space
	@echo "Checking PaaS space is active..."
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	@[ $$(cf target | grep -i 'space' | cut -d':' -f2) = "${PAAS_SPACE}" ] || (echo "${PAAS_SPACE} is not currently active cf space" && exit 1)
endef

.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: generate-manifest
generate-manifest: ## Generate manifest file for PaaS
	$(if ${DEPLOY_APPNAME},,$(error Must specify DEPLOY_APPNAME))
	$(if ${PAAS_SPACE},,$(error Must specify PAAS_SPACE))
	@scripts/generate-paas-manifest.sh ${DEPLOY_APPNAME} ${PAAS_SPACE} > manifest.yml

.PHONY: deploy-app
deploy-app: ## Deploys the app to PaaS
	$(call check_space)
	$(if ${DEPLOY_APPNAME},,$(error Must specify DEPLOY_APPNAME))

	@$(MAKE) generate-manifest

	cf apply-manifest -f manifest.yml

	cf set-env "${DEPLOY_APPNAME}" BUNDLE_WITHOUT "test"
	cf set-env "${DEPLOY_APPNAME}" JWT_ISSUER "${JWT_ISSUER}"
	cf set-env "${DEPLOY_APPNAME}" JWT_SECRET "${JWT_SECRET}"
	cf set-env "${DEPLOY_APPNAME}" STAGE "${PAAS_SPACE}"
	cf set-env "${DEPLOY_APPNAME}" EPB_UNLEASH_URI "${EPB_UNLEASH_URI}"
	cf set-env "${DEPLOY_APPNAME}" NEW_RELIC_LICENSE_KEY "${NEW_RELIC_LICENSE_KEY}"

	cf push "${DEPLOY_APPNAME}" --strategy rolling

.PHONY: setup-db
setup-db:
	@echo ">>>>> Creating DB"
	@bundle exec rake db:create
	@echo ">>>>> Migrating DB"
	@bundle exec rake db:migrate
	@echo ">>>>> Seeding DB with fuel code mapping data"
	@bundle exec rake db:seed
	@echo ">>>>> Populating Test DB"
	@bundle exec rake db:test:prepare
	@printf "\nDB setup complete.\nTo load fuel price data run 'bundle exec rake green_deal_update_fuel_data'.\n"

.PHONY: migrate-db-and-wait-for-success
migrate-db-and-wait-for-success:
	$(if ${DEPLOY_APPNAME},,$(error Must specify DEPLOY_APPNAME))
	cf run-task ${DEPLOY_APPNAME} --command "rake db:migrate" --name migrate
	@scripts/check-for-migration-result.sh

.PHONY: test
test:
	@STAGE=test bundle exec rake spec

.PHONY: run
run:
	$(if ${JWT_ISSUER},,$(error Must specify JWT_ISSUER))
	$(if ${JWT_SECRET},,$(error Must specify JWT_SECRET))
	$(if ${EPB_UNLEASH_URI},,$(error Must specify EPB_UNLEASH_URI))
	@bundle exec rackup -p 9191

.PHONY: format
format:
	@bundle exec rubocop --auto-correct --format offenses || true

.PHONY: slow-format
slow-format:
	@bundle exec rbprettier --write `find . -name '*.rb' -not -path './db/schema.rb'` *.ru Gemfile
	@bundle exec rubocop --auto-correct --format offenses || true

.PHONY: cf-check-api-db-migration-task
cf-check-api-db-migration-task: ## Get the status for the last migrate-db task
	@cf curl /v3/apps/`cf app --guid ${DEPLOY_APPNAME}`/tasks?order_by=-created_at | jq -r ".resources[0].state"

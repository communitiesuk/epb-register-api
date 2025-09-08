.DEFAULT_GOAL := help


.PHONY: help
help:
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: setup-db
setup-db:
	@echo "RACK_ENV is '${RACK_ENV}'"
	@echo ">>>>> Creating DB"
	@bundle exec rake db:create
	@echo ">>>>> Migrating DB"
	@bundle exec rake db:migrate
	@if [ "${RACK_ENV}" != "production" ]; then \
			echo ">>>>> Preparing DB for tests"; \
			RACK_ENV=test bundle exec rake db:create; \
			RACK_ENV=test bundle exec rake db:migrate; \
	fi
	@echo ">>>>> Seeding DB with fuel code mapping data"
	@bundle exec rake db:seed
	@printf "\nDB setup complete.\nTo load fuel price data run 'bundle exec rake maintenance:green_deal_update_fuel_data'.\n"


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
	@bundle exec rubocop --autocorrect || true

.PHONY: lint-api-spec
lint-api-spec:
	@npx spectral lint api/apidoc.yml -r api/.spectral.yaml

.PHONY: setup-hooks
setup-hooks:
	@scripts/setup-git-hooks.sh

.PHONY: seed-local-db
seed-local-db:
	make setup-db
	@echo ">>>>> Bootstrapping Dev Data"
	@bundle exec rake tasks:bootstrap_dev_data
	@echo ">>>>> Getting green deal fuel data"
	@bundle exec rake maintenance:green_deal_update_fuel_data
	@echo ">>>>> Seeding DB with fuel code mapping data"
	@bundle exec rake db:seed

.PHONY: destroy-test-postgres-container-if-exists
destroy-test-postgres-container-if-exists:
	@scripts/destroy-test-postgres-container-if-exists.sh

FROM ruby:3.1.3

ENV LANG=en_GB.UTF-8
ENV DATABASE_URL=postgresql://epb:superSecret30CharacterPassword@epb-register-api-db/epb
ENV EPB_UNLEASH_URI=http://epb-feature-flag/api
ENV EPB_DATA_WAREHOUSE_QUEUES_URI=redis://epb-data-warehouse-queues
ENV EPB_WORKER_REDIS_URI=redis://epb-register-api-worker-redis
ENV JWT_ISSUER=epb-auth-server
ENV JWT_SECRET=test-jwt-secret
ENV STAGE=development
ENV VALID_DOMESTIC_SCHEMAS:=SAP-Schema-19.1.0,SAP-Schema-19.0.0,SAP-Schema-18.0.0,SAP-Schema-NI-18.0.0,RdSAP-Schema-20.0.0,RdSAP-Schema-NI-20.0.0
ENV VALID_NON_DOMESTIC_SCHEMAS=CEPC-8.0.0,CEPC-NI-8.0.0


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -; \
    apt-get update -qq && apt-get install -y -qq --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app

RUN bundle install

RUN adduser --system --no-create-home nonroot
USER nonroot

ENTRYPOINT ["bundle", "exec", "sidekiq", "-r", "./sidekiq/config.rb"]

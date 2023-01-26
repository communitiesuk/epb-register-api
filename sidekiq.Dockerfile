FROM ruby:3.1.3

ENV LANG=en_GB.UTF-8
ENV DATABASE_URL=postgresql://epb:superSecret30CharacterPassword@epb-register-api-db/epb
ENV EPB_UNLEASH_URI=http://epb-feature-flag/api
ENV EPB_DATA_WAREHOUSE_QUEUES_URI=redis://epb-data-warehouse-queues
ENV EPB_WORKER_REDIS_URI=redis://epb-register-api-worker-redis
ENV JWT_ISSUER=epb-auth-server
ENV JWT_SECRET=test-jwt-secret
ENV STAGE=development
ENV VALID_DOMESTIC_SCHEMAS:=AP-Schema-19.0.0,SAP-Schema-18.0.0,SAP-Schema-NI-18.0.0,RdSAP-Schema-20.0.0,RdSAP-Schema-NI-20.0.0
ENV VALID_NON_DOMESTIC_SCHEMAS=CEPC-8.0.0,CEPC-NI-8.0.0


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY . /app
WORKDIR /app

RUN bundle install

ENTRYPOINT ["bundle", "exec", "sidekiq", "-r", "./sidekiq/config.rb"]

# epb-register-api

## Prerequisites

- [Ruby](https://www.ruby-lang.org/en/)
- [PostgreSQL](https://www.postgresql.org/)
- Bundler (run `gem install bundler`)

## Installing

`bundle install`

## Creating a local database

By default and application assumes that PostgreSQL 18 is installed locally,
with a role name "postgres" that has the `CREATEDB` and `SUPERUSER` privileges,
and is configured to use trust authentication.

If you are hosting postgres with a different setup, for example you need to set a password, then set a `DATABASE_URL` environmental variable.

```bash
# If your database is not on localhost with trust authentication then export a connection string
# DATABASE_URL="postgresql://postgres:my_password@localhost:5432/epb_development"

# Create database, or update the database if there is a pending migration
make setup-db

# Seed the database
make seed-local-db

# Delete the database
bundle exec rake db:drop
```

### You will need to set the following environment variables

`export STAGE=test`

Set the endpoint of unleash to be any valid URL. You will need to run your own local version of unleash if you want to use feature toggles.

`export EPB_UNLEASH_URI=https://google.com`

To decode and validate JWTs passed in to the API the environment variables `JWT_ISSUER` and `JWT_SECRET` need to be set.
The values for these should match those on the auth server being connected to.

`export JWT_ISSUER=dev.issuer`
`export JWT_SECRET=dev.secret`

## Running tests

`make test`

## Running server

`make run`

This will make the API available at `http://localhost:9191`.

## Code Formatting

To run Rubocop:

`make format`

## CI

Build commands are stored in the buildspec directory

## Docker image

### Build

The codebase contains a dockerfile for the api

To rebuild the api Docker image locally, run

`docker build . --tag epb-register-api`

### Run

#### Docker Desktop

You can run the created image in Docker Desktop by going to **Images** and pressing **Run** in the _Actions_ column.
This will create a persistent deployment and has an interface to provide multiple useful options.

#### CLI

##### API Service

`docker run -p {host_port}:80 -p {host_port2}:443 --name test-epb-register-api epb-register-api`

Where _host_port_ is a free port you want to use on your host machine to make calls to the API.

#### Communicating with other containers

When running the containers, you may want them to communicate with a containerized instance of PostgreSQL, Redis, or another container in general.
To do this, you will need to use a bridge network and connect any containers that need to communicate with each other to it

You can set up a bridge network using
`docker network create {network_name}`

And then connect the containers to the network when going to run them e.g.

- for the api `docker run -p {host_port}:80 -p {host_port2}:443 --network {network_name} --name test-epb-register-api epb-register-api`

## Application environmental variables

#### `APP_ENV`

Set the [Sintra environment](https://sinatrarb.com/intro.html#environments).
Should be one of "production", "development" or "test".

Sinatra will fallback to `RACK_ENV` or "development" if unset.

#### `RAILS_ENV`

[sintra-activerecord](https://github.com/sinatra-activerecord/sinatra-activerecord)
uses `APP_ENV` as the active record environment, but will fallback to `RAILS_ENV` if it is not supplied.

This should be one of "production", "development" or "test".  It will default to
"development" if neither `APP_ENV` or `RAILS_ENV` is set.

#### `RACK_ENV`

Used by rackup to choose the [default middleware stack](https://github.com/rack/rackup/blob/f3fa1d6ada90e9e7aa1f712488ddde87ea2a2075/lib/rackup/server.rb#L273).
Should be one of "development" (default) or "deployment". If set to any other value no middleware stack is loaded.

#### `STAGE`

The EPB environment. Can be one of "test", "development", "integration", "staging" or "production".

- Sets the unleash feature flag service app name to `toggles-#{stage}`
- Unless "development" or "test", enables Sentry and sets its environment value
- When "production" will log missing list errors if the approved software lists are missing
- When "production" sends Slack messages to the production channel instead of the pre-production channel
- When "test" disables using the reader connection
- When "test" disables pushing messages to data-warehouse redis queues

#### `DATABASE_URL`

The postgres URL of the primary (writer) database

#### `DATABASE_READER_URL`

The postgres URL of the replica (reader) database

#### `DOCKER_POSTGRES_PASSWORD`

The database password.  Only used in development and test when `DATABASE_URL` and `DATABASE_READER_URL` is not used.

#### `DOMESTIC_APPROVED_SOFTWARE`

A list of software approved for domestic calculations.

Must be a JSON encoded object in the form `{ software: string[] }`

If present, only non-domestic assessments using software in this list can be lodged.

#### `NON_DOMESTIC_APPROVED_SOFTWARE`

A list of software approved for non-domestic calculations.

Must be a JSON encoded object in the form `{ software: Record<string, string[]> }`.
The `Record` is a software name and an array of version prefixes.

If present, only domestic assessments using this software and with a version
starting with one of the version prefixes can be lodged.

#### `VALID_DOMESTIC_SCHEMAS`

A comma separated list of allowed schemas.  Only domestic assessments using
these schemas can be lodged.

#### `VALID_NON_DOMESTIC_SCHEMAS`

A comma separated list of allowed schemas.  Only non-domestic assessments using
these schemas can be lodged.

#### `EPB_UNLEASH_URI`

The URL of the unleash feature flag service.

#### `EPB_UNLEASH_AUTH_TOKEN`

Authentication token for the unleash feature flag service.

#### `EPB_ADDRESSING_URL`

The URL of the addressing API.

#### `EPB_DATA_WAREHOUSE_API_URL`

The URL of the data warehouse API.

#### `EPB_AUTH_CLIENT_ID`

The client id for connecting to the API services.

#### `EPB_AUTH_CLIENT_SECRET`

The client secret for connecting to the API services.

#### `EPB_AUTH_SERVER`

The URL of the auth server for connecting to the API services.

#### `EPB_API_DOCS_URL`

If present this will allow CORS for services with this origin.

#### `EPB_DATA_WAREHOUSE_QUEUES_URI`

URI of the redis server used for data-warehouse queues

#### `JWT_ISSUER`

Issuer for the JWT encoded auth token.

#### `JWT_SECRET`

Secret for the JWT encoded auth token.

#### `SILENT_EVENTS`

If "true" logging lodgement and assessor events to STDOUT will be disabled.

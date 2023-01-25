# epb-register-api

## Prerequisites

* [Ruby](https://www.ruby-lang.org/en/)
* [PostgreSQL](https://www.postgresql.org/)
* Bundler (run `gem install bundler`)

## Installing
`bundle install`

## Creating a local database

Ensure you have Postgres 11 installed. If you are working on a Mac, [this tutorial](https://www.codementor.io/engineerapart/getting-started-with-postgresql-on-mac-osx-are8jcopb) will take you through the process.

You will need to have a user with the role name postgres, which has the `Create DB` and `Superuser` permissions to create databases and install the `fuzzystrmatch` extension.

Once you have set this up, run the command to set up and seed your local database

`make seed-local-db`

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

The codebase contains two dockerfiles, one for the api itself and one for sidekiq
To rebuild the api Docker image locally, run

`docker build . --tag epb-register-api`

To rebuild the sidekiq Docker image locally, run

`docker build . --tag epb-register-api-worker -f sidekiq.Dockerfile`

### Run

#### Docker Desktop

You can run the created image in Docker Desktop by going to **Images** and pressing **Run** in the *Actions* column.
This will create a persistent deployment and has an interface to provide multiple useful options.

#### CLI

##### API Service

`docker run -p {host_port}:80 -p {host_port2}:443 --name test-epb-register-api epb-register-api`

Where *host_port* is a free port you want to use on your host machine to make calls to the API.

##### Sidekiq

`docker run --name test-epb-register-api-worker epb-register-api-worker`

#### Communicating with other containers
When running the containers, you may want them to communicate with a containerized instance of PostgreSQL, Redis, or another container in general.
To do this, you will need to use a bridge network and connect any containers that need to communicate with each other to it

You can set up a bridge network using
`docker network create {network_name}`

And then connect a container to the network when going to run it e.g.
* for the api `docker run -p {host_port}:80 -p {host_port2}:443 --network {network_name} --name test-epb-register-api epb-register-api`
* for sidekiq `docker run --network {network_name} --name test-epb-register-api-worker epb-register-api-worker`

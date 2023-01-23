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

To rebuild the Docker image locally, run

`docker build . --tag epb-register-api`

### Run

#### Docker Desktop

You can run the created image in Docker Desktop by going to **Images** and pressing **Run** in the *Actions* column.
This will create a persistent deployment and has an interface to provide multiple useful options.

#### CLI

To run the docker image with CLI

`docker run -p {host_port}:80 --name test-epb-register-api epb-register-api`

Where *host_port* is a free port you want to use on your host machine to make calls to the API.

If you want docker to communicate with a containarized instance of PostgreSQL, or another container in general, you will need to link them.

`docker run -p {host_port}:80 --link {linked_container_id} --name test-epb-register-api epb-register-api`

Where *linked_container_id* is the name or ID of the container you want to access.

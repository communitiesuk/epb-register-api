# epb-find-assessor

## Prerequisites

* [Ruby](https://www.ruby-lang.org/en/)
* [PostgreSQL](https://www.postgresql.org/)
* Bundler (run `gem install bundler:2.0.2`)

## Installing
`bundle install`

## Creating a local database

Ensure you have Postgres installed. If you are working on a Mac, [this tutorial](https://www.codementor.io/engineerapart/getting-started-with-postgresql-on-mac-osx-are8jcopb) will take you through the process.

You will need to have a user with the role name postgres, which has permission to create a database.

Once you have set this up, run the command

`make setup-db`

### You will need to set these two environment variables

`export STAGE=test`

Set the endpoint of unleash to be any valid URL. You will need to run your own local version of unleash if you want to use feature toggles.  

`export UNLEASH_URI=https://google.com`

## Running tests
`make test`

## Running server
`make run`

# CI
Build commands are stored in the buildspec directory

# What is this directory?

This directory contains the specification for the Energy performance register 
API.

## What is the .spectral.yaml file?

It's a config file for [Spectral](https://stoplight.io/open-source/spectral/), a linter for API spec files.

## How do I run Spectral against the API spec file?

From within the `api/` directory, run:

```sh
npx spectral lint api.yml
```

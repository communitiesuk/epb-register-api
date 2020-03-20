# Contributing to EBP Register API

This page is to provide information to anyone contributing to this repo. It will outline all the various aspects to consider when adding something to the API.

## When adding an item to the domestic energy assessment

* Migrations will need to be added.
* Don't forget to run the migrations followed by all of the tests
* Check the Gateway to ensure all methods get updated (check select statements and objects particularly)
* Make sure domain and boundary objects are up to date (consider if you need to add one if it is not already in place)
* Ensure all relevant use cases are checked. They may not need changing, but must be reviewed.
* Update the controller (principally put/post scheme object)
* Update the documentation in config/apidoc.yml to include the changes
* Check the aspirational documentation in api/api.yml is correct incase any updates or changes have made
* All of this should be done through TTD, with tests being checked and updated along the way
* In lib/tasks make sure to update all relevant rake tasks. Once they run locally, log into cloud flare on the command line and run the tasks there. Make sure to give them a moment for the changes to go through and then check the db tables. 

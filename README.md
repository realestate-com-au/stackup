# stackup

[![Build Status](https://travis-ci.org/realestate-com-au/stackup.svg?branch=master)](https://travis-ci.org/realestate-com-au/stackup)

Stackup attempts to simplify AWS Cloudformation stack creation process in
ruby projects by providing executable to perform common operations such
as apply(create/update), delete, recreate on stack along with validations on
templates. Operations which enforce a stack change will wait until
the change is complete.

## Installation

    $ gem install stackup

## Usage

The entry-point is the "stackup" command.

Most commands operate in the context of a named stack:

    $ stackup STACK-NAME ...

Called without stack-name, it will list stacks:

    $ stackup
    foo-bar-test
    zzz-production

### Stack create/update

Use sub-command "up" to create or update a stack, as appropriate:

    $ stackup myapp-test up template.json

This will:

  * update (or create) the named CloudFormation stack, using the specified template
  * monitor events until the stack update is complete

### Stack deletion

Sub-command "delete" deletes the stack.

### Stack inspection

Inspect details of a stack with:

    $ stackup myapp-test status
    $ stackup myapp-test resources
    $ stackup myapp-test outputs

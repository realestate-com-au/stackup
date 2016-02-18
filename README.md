# stackup

[![Build Status](https://travis-ci.org/realestate-com-au/stackup.svg?branch=master)](https://travis-ci.org/realestate-com-au/stackup)

Stackup provides a CLI and a simplified Ruby API for dealing with
AWS CloudFormation stacks.

## Why?

Stackup provides some advantages over using `awscli` or `aws-sdk` directly:

  - It treats stack changes as synchronous, streaming stack events until the
    stack reaches a stable state.

  - A `Stack#up` facade for `create`/`update` frees you from having to know
    whether your stack already exists or not.

  - Changes are (mostly) idempotent: "no-op" operations - e.g. deleting a
    stack that doesn't exist, or updating without a template change - are
    handled gracefully (i.e. without error).

## Installation

    $ gem install stackup

## Command-line usage

The entry-point is the "stackup" command.

Most commands operate in the context of a named stack:

    $ stackup STACK-NAME ...

Called with `--list`, it will list stacks:

    $ stackup --list
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

## Programmatic usage

Get a handle to a `Stack` object as follows:

    stack = Stackup.stack("my-stack")

You can pass an `Aws::CloudFormation::Client`, or client config,
to `Stackup`, e.g.

    stack = Stackup(credentials).stack("my-stack")

See {Stackup::Stack} for more details.

## Rake integration

Stackup integrates with Rake to generate handy tasks for managing a stack, e.g.

    require "stackup/rake_tasks"

    Stackup::RakeTasks("app") do |t|
      t.stack = "my-app"
      t.template = "app-template.json"
    end

providing tasks:

    rake app:diff       # Show pending changes to my-app stack
    rake app:down       # Delete my-app stack
    rake app:inspect    # Show my-app stack outputs and resources
    rake app:up         # Update my-app stack

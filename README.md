# stackup

Stackup attempts to simplify AWS Cloudformation stack creation process in
ruby projects by providing executable to perform common operations such
as apply(create/update), delete, recreate on stack along with validations on
templates. Task executions which enforce a stack change will wait until
ROLLBACK/COMPLETE or DELETE is signalled on the stack (useful in continuous
deployment environments to wait until deployment is successful).

## Installation

    $ gem install stackup

## Usage

The entry-point is the "stackup" command.

### CloudFormation

Use the "cloudformation" (or "cf") subcommand to manage CloudFormation stacks.

The "stack" subcommand lists stacks:

    $ stackup cf stacks

Most other commands operate in the context of a named stack:

    $ stackup cf stack STACK-NAME ...

To create or update a stack, based on a template, use "apply":

    $ stackup cf stack myapp-test apply

This will:

  * update (or create) the named CloudFormation stack, using the specified template
  * monitor events until the stack update is complete
  * print any stack "outputs"

Other stack subcommands include:

    $ stackup cf stack myapp-test outputs
    $ stackup cf stack myapp-test resources
    $ stackup cf stack myapp-test delete

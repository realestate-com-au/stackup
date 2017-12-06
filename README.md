# stackup

[![Gem Version](https://badge.fury.io/rb/stackup.png)](http://badge.fury.io/rb/stackup)
[![Build Status](https://travis-ci.org/realestate-com-au/stackup.svg?branch=master)](https://travis-ci.org/realestate-com-au/stackup)

Stackup provides a CLI and a simplified Ruby API for dealing with
AWS CloudFormation stacks.

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Why?](#why)
- [Installation](#installation)
- [Command-line usage](#command-line-usage)
	- [Stack create/update](#stack-createupdate)
	- [Specifying parameters](#specifying-parameters)
	- [YAML support](#yaml-support)
	- [AWS credentials](#aws-credentials)
	- [Using URLs as inputs](#using-urls-as-inputs)
	- [Stack deletion](#stack-deletion)
	- [Stack inspection](#stack-inspection)
	- [Change-set support](#change-set-support)
- [Programmatic usage](#programmatic-usage)
- [Rake integration](#rake-integration)
- [Docker image](#docker-image)

<!-- /TOC -->

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

    $ stackup myapp-test up -t template.json

This will:

  * update (or create) the named CloudFormation stack, using the specified template
  * monitor events until the stack update is complete

For more details on usage, see

    $ stackup STACK up --help

### Specifying parameters

Stack parameters can be be read from a file, e.g.

    $ stackup myapp-test up -t template.json -p parameters.json

Parameters can be specified as simple key-value pairs:

```json
{
  "IndexDoc": "index.html"
}
```

but also supports the [extended JSON format used by the AWS CLI](http://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-stack.html):


```json
[
  {
    "ParameterKey": "IndexDoc",
    "ParameterValue": "index.html",
    "UsePreviousValue": false
  }
]
```

You may specify `-p` multiple times; `stackup` will read and merge all the files:

    $ stackup myapp-test up -t template.json \
      -p defaults.json \
      -p overrides.json

Or, you can specify parameters on the command-line, via `-o`:

    $ stackup myapp-test up -t template.json \
      -o IndexDoc=index.html

### YAML support

`stackup` supports input files (template, parameters, tags) in YAML format, as well as JSON.

It also supports the [abbreviated YAML syntax for Cloudformation functions](https://aws.amazon.com/blogs/aws/aws-cloudformation-update-yaml-cross-stack-references-simplified-substitution/), though unlike the [AWS CLI](https://aws.amazon.com/cli/), Stackup normalises YAML input to JSON before invoking CloudFormation APIs.

### AWS credentials

The stackup command-line looks for AWS credentials in the [standard environment variables](https://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs).

You can also use the `--with-role` option to temporarily assume a different IAM role, for stack operations:

    $ stackup myapp-test up -t template.json \
      --with-role arn:aws:iam::862905684840:role/deployment

### Using URLs as inputs

You can use either local files, or HTTP URLs, to specify inputs; stack template, parameters, etc.

    $ stackup mystack up \
      -t https://s3.amazonaws.com/mybucket/stack-template.json

Where a template URL references an object in S3, `stackup` leverages [CloudFormation's native support](http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html) for such URLs, enabling use of much larger templates.

Non-S3 URLs are also supported, though in that case `stackup` must fetch the content itself:

    $ stackup mystack up \
      -t https://raw.githubusercontent.com/realestate-com-au/stackup/master/examples/template.yml

### Stack deletion

Sub-command "delete" deletes the stack.

### Stack inspection

Inspect details of a stack with:

    $ stackup myapp-test status
    $ stackup myapp-test resources
    $ stackup myapp-test outputs

### Change-set support

You can also create, list, inspect, apply and delete [change sets](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html) using `stackup`.

    $ stackup myapp-test change-sets
    $ stackup myapp-test change-set create -t template.json
    $ stackup myapp-test change-set inspect
    $ stackup myapp-test change-set apply

The change-set name defaults to "pending", but can be overridden using `--name`.

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

    Stackup::RakeTasks.new("app") do |t|
      t.stack = "my-app"
      t.template = "app-template.json"
    end

providing tasks:

    rake app:diff       # Show pending changes to my-app stack
    rake app:down       # Delete my-app stack
    rake app:inspect    # Show my-app stack outputs and resources
    rake app:up         # Update my-app stack

Parameters and tags may be specified via files, or as a Hash, e.g.

    Stackup::RakeTasks.new("app") do |t|
      t.stack = "my-app"
      t.template = "app-template.json"
      t.parameters = "production-params.json"
      t.tags = { "environment" => "production" }
    end

## Docker image

Stackup is also published as a Docker image. Basic usage is:

    docker run --rm \
        -v "`pwd`:/cwd" \
        -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
        -e AWS_DEFAULT_REGION \
        realestate/stackup:latest ...

If you're sensible, you'll replace "latest", with a specific [version](https://rubygems.org/gems/stackup/versions).

The default working-directory within the container is `/cwd`;
hence the volume mount to make files available from the host system.

## IAM Permissions

### up

This policy grants the principal all actions required by `stackup up` for any cloudformation stack:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStackResource",
                "cloudformation:DescribeStacks",
                "cloudformation:SetStackPolicy",
                "cloudformation:UpdateStack"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

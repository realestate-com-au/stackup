# CHANGES

## 1.7.0 (2020-11-25)

* Feature: --no-fail-on-empty-change-set

## 1.6.0 (2020-11-19)

* Feature: Support --service-role-arn on "change-set create"

## 1.5.1 (2020-11-16)

* Fix: Recognise that template is in S3 when URL is formatted like `s3.REGION.amazonaws.com`

## 1.5.0 (2020-04-21)

* Feature: --preserve-template-formatting

## 1.4.6 (2019-12-09)

* Fix: Don't error out when receiving tags in AWS style (array of hashes) from YAML or JSON file

## 1.4.5 (2019-10-03)

* Fix: Tags in RakeTasks

## 1.4.4 (2019-10-03)

* Fix: Loading RakeTasks
* Removes CI support for older rubies

## 1.4.3 (2019-09-05)

* Add support for CloudFormation capabilities via CLI and Rake
* Fix: Prevent failure when creating a stack with change sets

## 1.4.2 (2019-01-21)

* Fix #64: Create and Update functions should not mutate the options parameter

## 1.4.1 (2018-11-07)

* Fix: diff method had a new required value in v1.4.0. This now defaults to nil in the method signature.

## 1.4.0 (2018-11-01)

* Add `--context-lines` option to `diff`.
* Fix #60: requiring all of "aws-sdk-resources" causes slow gem loading.

## 1.3.1 (2018-06-05)

* Dependency upgrades. Notably ruby 2.5 in the docker release, and aws-sdk v3

## 1.3.0 (2018-05-22)

* Fix #53: Add support for CloudFormation Service Role

## 1.2.0 (2017-10-24)

* Add support for change-sets.

## 1.1.3 (2017-05-01)

* Fix #39: parse error when JSON-like text is embedded in YAML.

## 1.1.1 (2017-02-23)

* The `stackup` CLI now allows stack template and policy documents to be specified as URLs.
  * Template URL must point to a template stored in an Amazon S3 bucket, e.g. `https://s3-ap-southeast-2.amazonaws.com/bucket/template.json`.
  * Policy URL must point to an object located in an S3 bucket in the same region as the stack.

## 1.0.4 (2017-01-04)

* Fix #34: make YAML parsing work in ruby-2.0.

## 1.0.3 (2016-12-19)

* Support "!GetAtt" with an array (rather than dotted string).

## 1.0.2 (2016-12-19)

* Add `tags` subcommand.

## 1.0.1 (2016-12-07)

* Fix handling of "!GetAtt" in CloudFormation YAML.
* Special-case "!GetAZs" without an argument.
* Add Stack#template_body.

## 1.0.0 (2016-10-07)

* Add support for CloudFormation YAML extensions (e.g. `!Ref`).

## 0.9.5 (2016-09-26)

* Add `--with-role` option, to assume a role for stack operations.

## 0.9.4 (2016-09-03)

* Support multiple parameters files.

## 0.9.3 (2016-08-21)

* Specify CAPABILITY_NAMED_IAM by default, allowing creation of named IAM roles.

## 0.9.2 (2016-08-04)

* Make poll_interval (during deployment) configurable.
* Add `--wait-poll-interval` option.
* Minimise calls to "DescribeStackEvents" (esp. for older stacks).
* Add `--no-wait` option.

## 0.8.4 (2016-07-08)

* Ensure stack tag values are strings.

## 0.8.3 (2016-06-16)

* Release as a Docker image, too.

## 0.8.2 (2016-05-31)

* CLI catches and reports any `Aws::Errors::ServiceError`.
* Add `--retry-limit` option.
* Normalize templates (sort by key) before diff-ing them.

## 0.8.1 (2016-04-13)

* Add "outputs" rake task.

## 0.8.0 (2016-03-15)

* Add support for stack tags.
* Add `--region` and `--override` options to CLI.
* Be more informative when stack doesn't require updates (issue #19).
* Display time of stack events.

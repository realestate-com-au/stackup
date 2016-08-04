## 0.9.1 (2016-08-04)

* Revert default poll interval to 5 seconds.

## 0.9.0 (2016-08-04)

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

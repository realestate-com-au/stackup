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

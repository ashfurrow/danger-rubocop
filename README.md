[![CircleCI](https://circleci.com/gh/ashfurrow/danger-rubocop.svg?style=svg)](https://circleci.com/gh/ashfurrow/danger-rubocop)

# Danger Rubocop

A [Danger](https://github.com/danger/danger) plugin for [Rubocop](https://github.com/bbatsov/rubocop) (and compatible wrappers such as [Standard](https://github.com/testdouble/standard/)).

## Installation

Add this line to your Gemfile:

```rb
gem 'danger-rubocop'
```

## Usage

Run Ruby files through Rubocop.
Results are passed out as a table in markdown.


> Specifying custom config file.
```ruby
rubocop.lint
```

> Lint specific files in a folder, when they change

```ruby
public_files = (git.modified_files + git.added_files).select { |path| path.include?("/public/") }
rubocop.lint public_files
```

> Submit comments only for changed lines

```ruby
github.dismiss_out_of_range_messages
rubocop.lint inline_comment: true
```

> Format using `standardrb` instead of Rubocop

```ruby
rubocop.lint rubocop_cmd: 'standardrb'
```

#### Methods

`lint(config: Hash)`

Runs Ruby files through Rubocop. Generates a `markdown` list of warnings.

This method accepts a configuration hash.
The following keys are supported:

* `files`: array of file names or glob patterns to determine files to lint. If omitted, this will lint only the files changed in the pull request. To lint all files every time, pass an empty string; this is the equivalent of typing `rubocop` without specifying any files, and will follow the rules in your `.rubocop.yml`.
* `force_exclusion`: pass `true` to pass `--force-exclusion` argument to Rubocop.
  (this option will instruct rubocop to ignore the files that your rubocop config ignores,
  despite the plugin providing the list of files explicitly)
* `inline_comment`: pass `true` to comment inline of the diffs.
* `fail_on_inline_comment`: pass `true` to use `fail` instead of `warn` on inline comment.
* `report_severity`: pass `true` to use `fail` or `warn` based on Rubocop severity.
* `report_danger`: pass true to report errors to Danger, and break CI.
* `include_cop_names`: pass true to include cop names when reporting errors with `report_danger`.
* `config`: path to the `.rubocop.yml` file.
* `only_report_new_offenses`: pass `true` to only report offenses that are in current user's scope.
   Note that this won't mark offenses for _Metrics/XXXLength_ if you add lines to an already existing scope.
* `include_cop_names`: Prepends cop names to the output messages. Example: "Layout/EmptyLinesAroundBlockBody: Extra empty line detected at block body end."
* `rubocop_cmd`: Allows you to change the rubocop executable that's invoked. This is used to support rubocop wrappers like [Standard](https://github.com/testdouble/standard/) by passing `standardrb` as the value.


Passing `files` as only argument is also supported for backward compatibility.

## License

MIT

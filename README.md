[![CircleCI](https://circleci.com/gh/ashfurrow/danger-rubocop.svg?style=svg)](https://circleci.com/gh/ashfurrow/danger-rubocop)

# Danger Rubocop

A [Danger](https://github.com/danger/danger) plugin for [Rubocop](https://github.com/bbatsov/rubocop).

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

#### Methods

`lint(config: Hash)`

Runs Ruby files through Rubocop. Generates a `markdown` list of warnings.

This method accepts configuration hash.
The following keys are supported:

* `files`: array of file names or glob patterns to determine files to lint
* `force_exclusion`: pass `true` to pass `--force-exclusion` argument to Rubocop.
  (this option will instruct rubocop to ignore the files that your rubocop config ignores,
  despite the plugin providing the list of files explicitely)
* `inline_comment`: pass `true` to comment inline of the diffs.
* `fail_on_inline_comment`: pass `true` to use `fail` instead of `warn` on inline comment.
* `report_danger`: pass true to report errors to Danger, and break CI.
* `config`: path to the `.rubocop.yml` file.
* `only_report_new_offenses`: pass `true` to only report offenses that are in current user's scope.
   Note that this won't mark offenses for _Metrics/XXXLength_ if you add lines to an already existing scope.


Passing `files` as only argument is also supported for backward compatibility.

## License

MIT

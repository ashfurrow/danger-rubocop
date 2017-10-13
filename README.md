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


#### Methods

`lint(config: Hash)`

Runs Ruby files through Rubocop. Generates a `markdown` list of warnings.

This method accepts configuration hash.
The following keys are supported:

* `files`: array of file names or glob patterns to determine files to lint
* `force_exclusion`: pass `true` to pass `--force-exclusion` argument to Rubocop.
* `inline_comment`: pass `true` to comment inline of the diffs.
* `report_danger`: pass true to report errors to Danger, and break CI.
  
  (this option will instruct rubocop to ignore the files that your rubocop config ignores,
  despite the plugin providing the list of files explicitely)

Passing `files` as only argument is also supported for backward compatibility.

## License

MIT

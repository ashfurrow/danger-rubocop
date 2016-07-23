[![CircleCI](https://circleci.com/gh/ashfurrow/danger-rubocop.svg?style=svg)](https://circleci.com/gh/ashfurrow/danger-rubocop)

# Danger Rubocop

A [Danger](https://github.com/danger/danger) plugin for [Rubocop](https://github.com/bbatsov/rubocop).

## Installation

Add this line to your Gemfile:

```rb
gem 'danger-rubocop'
```

## Usage

The easiest way to use is just add this to your Dangerfile:

```rb
rubocop.lint
```

That will lint any changed or added Ruby files in the PR.

You can also provide a list of files manually:

```rb
# Look through all changed ruby files
rb_files = (modified_files + added_files).select { |f| f.end_with?(".rb") }

rubocop.run rb_files
```

## License

MIT
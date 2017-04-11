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


`lint(files: String)`

 Runs Ruby files through Rubocop. Generates a `markdown` list of warnings.



## License

MIT

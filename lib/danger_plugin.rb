module Danger
  class DangerRubocop < Plugin
    def lint(files = nil, whitelist = [], cops_to_ignore = [])
      @whitelist = whitelist
      rubocop_offending_files = offending_files(files, cops_to_ignore)
      return unless rubocop_offending_files.any?
      markdown offenses_message(rubocop_offending_files)
    end

    def offending_files(files = nil, cops_to_ignore = [])
      files_to_lint = fetch_files_to_lint(files)
      rubocop(files_to_lint, cops_to_ignore)
    end

    private

    def fetch_files_to_lint(files = nil)
      @files_to_lint ||= (files ? Dir.glob(files) : (git.modified_files + git.added_files))
    end

    def rubocop(files_to_lint, cops_to_ignore = [])
      rubocop_output = `#{'bundle exec ' if need_bundler?}rubocop -f json #{files_to_lint.join(' ')}`

      JSON.parse(rubocop_output)['files'].map do |file|
        file['offenses'].reject! do |offense|
          cops_to_ignore.include?(offense['cop_name'])
        end
        file unless file['offenses'].empty?
      end.compact
    end

    def offenses_message(offending_files)
      require 'terminal-table'

      message = "### Rubocop violations\n\n"
      table = Terminal::Table.new(
        headings: %w(Required File Line Reason),
        style: { border_i: '|' },
        rows: offending_files.flat_map do |file|
          file['offenses'].map do |offense|
            [
              required?(file['path']) ? ':x:' : '',
              file['path'],
              offense['location']['line'],
              offense['message']
            ]
          end
        end
      ).to_s
      message + table.split("\n")[1..-2].join("\n")
    end

    def required?(file_path)
      (@whitelist + git.added_files).include?(file_path)
    end

    def need_bundler?
      File.exist?('Gemfile') && !ENV['CIRCLECI_BUNDLER']
    end
  end
end

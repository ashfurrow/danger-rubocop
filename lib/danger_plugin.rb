module Danger
  class DangerRubocop < Plugin
    def lint(files = nil)
      rubocop_offending_files = offending_files(files)
      return unless rubocop_offending_files.any?
      [markdown(offenses_message(rubocop_offending_files)), rubocop_offending_files]
    end

    private

    def offending_files(files = nil)
      files_to_lint = fetch_files_to_lint(files)
      rubocop(files_to_lint)
    end

    def fetch_files_to_lint(files = nil)
      @files_to_lint ||= (files ? Dir.glob(files) : (git.modified_files + git.added_files))
    end

    def rubocop(files_to_lint)
      rubocop_output = `#{'bundle exec ' if need_bundler?}rubocop -f json #{files_to_lint.join(' ')}`
      JSON.parse(rubocop_output)['files'].select { |f| f['offenses'].any? }
    end

    def offenses_message(offending_files)
      require 'terminal-table'

      message = "### Rubocop violations\n\n"
      table = Terminal::Table.new(
        headings: %w(File Line Reason),
        style: { border_i: '|' },
        rows: offending_files.flat_map do |file|
          file['offenses'].map do |offense|
            [
              file['path'],
              offense['location']['line'],
              offense['message']
            ]
          end
        end
      ).to_s
      message + table.split("\n")[1..-2].join("\n")
    end

    def need_bundler?
      File.exist?('Gemfile') && !ENV['CIRCLECI_BUNDLER']
    end
  end
end

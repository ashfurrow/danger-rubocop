module Danger
  # Run Ruby files through Rubocop.
  # Results are passed out as a table in markdown.
  #
  # @example Specifying custom config file.
  #
  #          rubocop.lint
  #
  # @example Lint specific files in a folder, when they change
  #
  #  public_files = (modified_files + added_files).select { |path| path.include?("/public/") }
  #  rubocop.lint public_files
  #
  #
  # @see  Moya/Aeryn
  # @tags ruby, rubocop, linter
  #
  class DangerRubocop < Plugin
    # Runs Ruby files through Rubocop. Generates a `markdown` list of warnings.
    #
    # @param   [String] files
    #          A globbed string which should return the files that you want to
    #          run through, defaults to nil. If nil, modified and added files
    #          from the diff will be used.
    # @return  [void]
    #
    def lint(files = nil)
      files_to_lint = fetch_files_to_lint(files)

      return if offending_files.empty?

      markdown offenses_message(offending_files)
    end
    
    def offending_files(files = nil)
      files_to_lint = fetch_files_to_lint(files)
      rubocop(files_to_lint)
    end

    private

    def rubocop(files_to_lint)
      rubocop_output = `#{'bundle exec ' if File.exist?('Gemfile')}rubocop -f json`

      JSON.parse(rubocop_output)['files']
        .select { |f| files_to_lint.include?(f['path']) && f['offenses'].any? }
    end

    def offenses_message(offending_files)
      require 'terminal-table'

      message = "### Rubocop violations\n\n"
      table = Terminal::Table.new(
        headings: %w(File Line Reason),
        style: { border_i: '|' },
        rows: offending_files.flat_map do |file|
          file['offenses'].map do |offense|
            [file['path'], offense['location']['line'], offense['message']]
          end
        end
      ).to_s
      message + table.split("\n")[1..-2].join("\n")
    end
    
    def fetch_files_to_lint(files = nil)
      @files_to_lint ||= (files ? Dir.glob(files) : (git.modified_files + git.added_files))
    end
  end
end

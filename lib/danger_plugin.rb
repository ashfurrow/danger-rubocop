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
      files_to_lint = files ? Dir.glob(files) : (git.modified_files + git.added_files)
      files_to_lint.select! { |f| f.end_with? 'rb' }

      offending_files = rubocop(files_to_lint)
      return if offending_files.empty?

      markdown offenses_message(offending_files)
    end

    private

    def rubocop(files_to_lint)
      rubocop_results = files_to_lint.flat_map do |f|
        prefix = File.exist?('Gemfile') ? 'bundle exec' : ''
        JSON.parse(`#{prefix} rubocop -f json #{f}`)['files']
      end
      rubocop_results.select { |f| f['offenses'].count > 0 }
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
  end
end

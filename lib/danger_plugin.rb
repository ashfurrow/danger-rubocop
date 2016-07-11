module Danger

  # Run Ruby files through Rubocop.
  # Results are passed out as a table in markdown.
  #
  # @example Specifying custom config file.
  #
  #          rubocop.run
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
    def run(files=nil)
      files_to_lint = files ? Dir.glob(files) : (modified_files + added_files)
      files_to_lint.select! { |f| f.end_with? 'rb' }
      rubocop_results = files_to_lint.map { |f| JSON.parse(`bundle exec rubocop -f json #{f}`)['files'] }.flatten
      offending_files = rubocop_results.select { |f| f['offenses'].count > 0 }

      return if offending_files.empty?

      require 'terminal-table'



      message = "### Rubocop violations\n\n"
      message += Terminal::Table.new(
        headings: %w(File Line Reason),
        rows: offending_files.flat_map do |file|
          file['offenses'].map do |offense|
            [file['path'], offense['location']['line'], offense['message']]
          end
        end
      ).to_s

      markdown message
    end
  end
end

require 'shellwords'

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
    def lint(config = nil)
      config = config.is_a?(Hash) ? config : { files: config }
      files = config[:files]
      force_exclusion = config[:force_exclusion] || false
      inline_comment = config[:inline_comment] || false

      files_to_lint = fetch_files_to_lint(files)
      files_to_report = rubocop(files_to_lint, force_exclusion)

      return if files_to_report.empty?

      if inline_comment
        warn_each_line(files_to_report)
      else
        markdown offenses_message(files_to_report)
      end
    end

    private

    def rubocop(files_to_lint, force_exclusion)
      base_command = 'rubocop -f json'
      base_command << ' --force-exclusion' if force_exclusion

      rubocop_output = `#{'bundle exec ' if File.exist?('Gemfile')}#{base_command} #{files_to_lint}`

      JSON.parse(rubocop_output)['files']
        .select { |f| f['offenses'].any? }
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

    def warn_each_line(offending_files)
      offending_files.flat_map do |file|
        file['offenses'].map do |offense|
          warn(offense['message'], file: file['path'], line: offense['location']['line'])
        end
      end
    end

    def fetch_files_to_lint(files = nil)
      to_lint = (files ? Dir.glob(files) : (git.modified_files + git.added_files))
      Shellwords.join(to_lint)
    end
  end
end

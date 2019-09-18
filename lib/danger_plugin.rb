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
      config_path = config[:config]
      report_danger = config[:report_danger] || false
      only_report_new_offenses = config[:only_report_new_offenses] || false
      inline_comment = config[:inline_comment] || false
      fail_on_inline_comment = config[:fail_on_inline_comment] || false

      files_to_lint = fetch_files_to_lint(files)
      files_to_report = rubocop(files_to_lint, force_exclusion, only_report_new_offenses, config_path: config_path)

      return if files_to_report.empty?
      return report_failures files_to_report if report_danger

      if inline_comment
        add_violation_for_each_line(files_to_report, fail_on_inline_comment)
      else
        markdown offenses_message(files_to_report)
      end
    end

    private

    def rubocop(files_to_lint, force_exclusion, only_report_new_offenses, config_path: nil)
      base_command = ['rubocop', '-f', 'json']
      base_command.concat(['--force-exclusion']) if force_exclusion
      base_command.concat(['--config', config_path.shellescape]) unless config_path.nil?

      rubocop_output = `#{'bundle exec ' if File.exist?('Gemfile')}#{base_command.join(' ')} #{files_to_lint}`

      return [] if rubocop_output.empty?

      files = JSON.parse(rubocop_output)['files']

      filter_out_offenses(files) if only_report_new_offenses

      files.select { |f| f['offenses'].any? }
    end

    def filter_out_offenses(files)
      files.each do |file|
        added_lines = added_lines(file['path']).to_set
        file['offenses'].select! do |offense|
          added_lines.include?(offense['location']['line'])
        end
      end
    end

    def added_lines(path)
      git.diff_for_file(path)
         .patch
         .split("\n@@")
         .tap(&:shift)
         .flat_map do |chunk|
           first_line, *diff = chunk.split("\n")
           # Get start from diff.
           lineno = first_line.match(/\+(\d+),(\d+)/).captures.first.to_i
           diff.each_with_object([]) do |current_line, added_lines|
             lineno += 1 unless current_line.start_with?('-')
             added_lines << lineno if current_line.start_with?('+')
             added_lines
           end
         end
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

    def report_failures(offending_files)
      offending_files.each do |file|
        file['offenses'].each do |offense|
          fail "#{file['path']} | #{offense['location']['line']} | #{offense['message']}"
        end
      end
    end

    def add_violation_for_each_line(offending_files, fail_on_inline_comment)
      offending_files.flat_map do |file|
        file['offenses'].map do |offense|
          arguments = [
            offense['message'],
            {
              file: file['path'],
              line: offense['location']['line']
            }
          ]
          if fail_on_inline_comment
            fail(*arguments)
          else
            warn(*arguments)
          end
        end
      end
    end

    def fetch_files_to_lint(files = nil)
      to_lint = (files ? Dir.glob(files) : (git.modified_files + git.added_files))
      Shellwords.join(to_lint)
    end
  end
end

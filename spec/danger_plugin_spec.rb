require File.expand_path('spec_helper', __dir__)

module Danger
  describe DangerRubocop do
    it 'is a plugin' do
      expect(Danger::DangerRubocop < Danger::Plugin).to be_truthy
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @rubocop = testing_dangerfile.rubocop
      end

      describe "#filter_out_offenses" do
        let(:files_within_pr) do
          [
            {
              'path' => 'lib/version.rb',
              'offenses' => [
                {
                  'message' => 'No.',
                  'location' => { 'line' => 41 }
                }
              ]
            }
          ]
        end

        let(:files_outside_pr) do
          [
            {
              'path' => 'lib/version.rb',
              'offenses' => [
                {
                  'message' => 'No.',
                  'location' => { 'line' => 20 }
                }
              ]
            }
          ]
        end
        subject { @rubocop }

        before do
          allow(@rubocop.git).to receive(:diff_for_file).with('lib/version.rb') do
            instance_double('Git::Diff::DiffFile', patch: <<~DIFF)
            diff --git a/lib/version.rb b/lib/version.rb
            index 66d3a986..5e8074a8 100644
            --- a/lib/version.rb
            +++ b/lib/version.rb
            @@ -32,4 +40,3 @@
             line 1
            -removed
            -line 2 old version
            +line 2 with offense
             line 3
            DIFF
          end
        end

        it 'filters out offenses not in the pr' do
          p described_class
          expect(subject.send(:filter_out_offenses, files_outside_pr)).to eq(
            [
              {
                'path' => 'lib/version.rb',
                'offenses' => []
              }
            ]
          )
        end

        it 'keeps offenses in the pr' do
          expect(subject.send(:filter_out_offenses, files_within_pr.dup)).to eq(
            [
              {
                'path' => 'lib/version.rb',
                'offenses' => [
                  {
                    'message' => 'No.',
                    'location' => { 'line' => 41 }
                  }
                ]
              }
            ]
          )
        end
      end

      describe :added_lines do
        before do
          allow(@rubocop.git).to receive(:diff_for_file).with('SAMPLE') do
            instance_double('Git::Diff::DiffFile', patch: <<~DIFF)
            diff --git a/SAMPLE b/SAMPLE
            new file mode 100644
            index 0000000..7bba8c8
            --- /dev/null
            +++ b/SAMPLE
            @@ -0,0 +1,2 @@
            +line 1
            +line 2
            DIFF
          end
        end

        it 'handles git diff' do
          expect(@rubocop.send(:added_lines, 'SAMPLE')).to eq([1, 2])
        end

        context "single line added to a new file" do
          before do
            allow(@rubocop.git).to receive(:diff_for_file).with('SAMPLE') do
              instance_double('Git::Diff::DiffFile', patch: <<~DIFF)
              diff --git a/SAMPLE b/SAMPLE
              new file mode 100644
              index 0000000..7bba8c8
              --- /dev/null
              +++ b/SAMPLE
              @@ -0,0 +1 @@
              +line 1
              DIFF
            end
          end

          it 'handles git diff' do
            expect(@rubocop.send(:added_lines, 'SAMPLE')).to eq([1])
          end
        end

        context 'no such file' do
          before do
            allow(@rubocop.git).to receive(:diff_for_file).with('SAMPLE').and_return(nil)
          end

          it 'return empty array' do
            expect(@rubocop.send(:added_lines, 'SAMPLE')).to eq([])
          end
        end
      end

      describe :lint_files do
        let(:response_ruby_file) do
          {
            'files' => [
              {
                'path' => 'spec/fixtures/ruby_file.rb',
                'offenses' => [
                  {
                    'cop_name' => 'Syntax/WhetherYouShouldDoThat',
                    'message' => "Don't do that!",
                    'severity' => 'warning',
                    'location' => { 'line' => 13 }
                  }
                ]
              }
            ]
          }.to_json
        end

        let(:response_another_ruby_file) do
          {
            'files' => [
              {
                'path' => 'spec/fixtures/another_ruby_file.rb',
                'offenses' => [
                  {
                    'cop_name' => 'Syntax/WhetherYouShouldDoThat',
                    'message' => "Don't do that!",
                    'severity' => 'error',
                    'location' => { 'line' => 23 }
                  }
                ]
              }
            ]
          }.to_json
        end

        it 'handles a rubocop report for specified files' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types --config path/to/rubocop.yml spec/fixtures/ruby_file.rb')
            .and_return(response_ruby_file)

          # Do it
          @rubocop.lint(files: 'spec/fixtures/ruby*.rb', config: 'path/to/rubocop.yml')

          output = @rubocop.status_report[:markdowns].first.message

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("spec/fixtures/ruby_file.rb | 13   | Don't do that!")
        end

        it 'includes cop names when include_cop_names is set' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types --config path/to/rubocop.yml spec/fixtures/ruby_file.rb')
            .and_return(response_ruby_file)

          # Do it
          @rubocop.lint(files: 'spec/fixtures/ruby*.rb', config: 'path/to/rubocop.yml', include_cop_names:  true)

          output = @rubocop.status_report[:markdowns].first.message

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("spec/fixtures/ruby_file.rb | 13   | Syntax/WhetherYouShouldDoThat: Don't do that!")
        end

        it 'handles a rubocop report for specified files (legacy)' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
            .and_return(response_ruby_file)

          # Do it
          @rubocop.lint('spec/fixtures/ruby*.rb')

          output = @rubocop.status_report[:markdowns].first.message

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("spec/fixtures/ruby_file.rb | 13   | Don't do that!")
        end

        it 'appends --force-exclusion argument when force_exclusion is set' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types --force-exclusion spec/fixtures/ruby_file.rb')
            .and_return(response_ruby_file)

          # Do it
          @rubocop.lint(files: 'spec/fixtures/ruby*.rb', force_exclusion: true)

          output = @rubocop.status_report[:markdowns].first.message

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("spec/fixtures/ruby_file.rb | 13   | Don't do that!")
        end

        it 'handles a rubocop report for files changed in the PR' do
          allow(@rubocop.git).to receive(:added_files).and_return([])
          allow(@rubocop.git).to receive(:modified_files)
            .and_return(["spec/fixtures/old_file_name.rb", "spec/fixtures/another_ruby_file.rb"])
          allow(@rubocop.git).to receive(:renamed_files)
            .and_return([{before: "spec/fixtures/old_file_name.rb", after: "spec/fixtures/new_file_name.rb"}])

          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/new_file_name.rb spec/fixtures/another_ruby_file.rb')
            .and_return(response_another_ruby_file)

          @rubocop.lint

          output = @rubocop.status_report[:markdowns].first.message

          expect(output).to include('Rubocop violations')
          expect(output).to include("spec/fixtures/another_ruby_file.rb | 23   | Don't do that!")
        end

        it 'is formatted as a markdown table' do
          allow(@rubocop.git).to receive(:modified_files)
            .and_return(['spec/fixtures/ruby_file.rb'])
          allow(@rubocop.git).to receive(:added_files).and_return([])
          allow(@rubocop.git).to receive(:renamed_files).and_return([])
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
            .and_return(response_ruby_file)

          @rubocop.lint

          formatted_table = <<-EOS
### Rubocop violations\n
| File                       | Line | Reason         |
|----------------------------|------|----------------|
| spec/fixtures/ruby_file.rb | 13   | Don't do that! |
EOS
          expect(@rubocop.status_report[:markdowns].first.message).to eq(formatted_table.chomp)
          expect(@rubocop).not_to receive(:fail)
        end

        context 'with inline_comment option' do
          context 'without fail_on_inline_comment option' do
            it 'reports violations as line by line warnings' do
              allow(@rubocop.git).to receive(:modified_files)
                .and_return(['spec/fixtures/ruby_file.rb'])
              allow(@rubocop.git).to receive(:added_files).and_return([])
              allow(@rubocop.git).to receive(:renamed_files).and_return([])
              allow(@rubocop).to receive(:`)
                .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
                .and_return(response_ruby_file)

              @rubocop.lint(inline_comment: true)

              expect(@rubocop.violation_report[:warnings].first.to_s)
                .to eq("Violation Don't do that! { sticky: false, file: spec/fixtures/ruby_file.rb, line: 13, type: warning }")
            end
          end

          context 'with fail_on_inline_comment option' do
            before do
              allow(@rubocop.git).to receive(:modified_files)
                .and_return(['spec/fixtures/ruby_file.rb'])
              allow(@rubocop.git).to receive(:added_files).and_return([])
              allow(@rubocop.git).to receive(:renamed_files).and_return([])
              allow(@rubocop).to receive(:`)
                .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
                .and_return(response_ruby_file)
            end

            it 'reports violations as line by line failures' do
              @rubocop.lint(fail_on_inline_comment: true, inline_comment: true)

              expect(@rubocop.violation_report[:errors].first.to_s)
                .to eq("Violation Don't do that! { sticky: false, file: spec/fixtures/ruby_file.rb, line: 13, type: error }")
            end

            it 'includes cop names when include_cop_names is set' do
              @rubocop.lint(fail_on_inline_comment: true, inline_comment: true, include_cop_names: true)

              expect(@rubocop.violation_report[:errors].first.to_s)
                .to eq("Violation Syntax/WhetherYouShouldDoThat: Don't do that! { sticky: false, file: spec/fixtures/ruby_file.rb, line: 13, type: error }")
            end
          end
        end

        context 'with report_severity option' do
          context 'file with error' do
            it 'reports violations by rubocop severity' do
              allow(@rubocop.git).to receive(:added_files).and_return([])
              allow(@rubocop.git).to receive(:modified_files)
                .and_return(["spec/fixtures/another_ruby_file.rb"])
              allow(@rubocop.git).to receive(:renamed_files).and_return([])

              allow(@rubocop).to receive(:`)
                .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/another_ruby_file.rb')
                .and_return(response_another_ruby_file)

              @rubocop.lint(report_severity: true, inline_comment: true)

              expect(@rubocop.violation_report[:errors].first.to_s)
                .to eq("Violation Don't do that! { sticky: false, file: spec/fixtures/another_ruby_file.rb, line: 23, type: error }")
            end
          end
        end

        context 'file with warning' do
          it 'reports violations by rubocop severity' do
            allow(@rubocop.git).to receive(:added_files).and_return([])
            allow(@rubocop.git).to receive(:modified_files)
              .and_return(["spec/fixtures/ruby_file.rb"])
            allow(@rubocop.git).to receive(:renamed_files).and_return([])

            allow(@rubocop).to receive(:`)
              .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
              .and_return(response_ruby_file)

            @rubocop.lint(report_severity: true, inline_comment: true)

            expect(@rubocop.violation_report[:warnings].first.to_s)
              .to eq("Violation Don't do that! { sticky: false, file: spec/fixtures/ruby_file.rb, line: 13, type: warning }")
          end
        end

        context 'using standardrb cmd' do
          it 'executes using the standardrb cmd' do
            allow(@rubocop).to receive(:`)
              .with('bundle exec standardrb -f json --only-recognized-file-types --config path/to/rubocop.yml spec/fixtures/ruby_file.rb')
              .and_return(response_ruby_file)

            # Do it
            @rubocop.lint(files: 'spec/fixtures/ruby*.rb', rubocop_cmd: 'standardrb', config: 'path/to/rubocop.yml')
          end
        end

        describe 'a filename with special characters' do
          it 'is shell escaped' do
            modified_files = [
              'spec/fixtures/shellescape/ruby_file_with_parens_(abc).rb',
              'spec/fixtures/shellescape/ruby_file with spaces.rb',
              'spec/fixtures/shellescape/ruby_file\'with_quotes.rb'
            ]
            allow(@rubocop.git).to receive(:modified_files)
              .and_return(modified_files)
            allow(@rubocop.git).to receive(:added_files).and_return([])
            allow(@rubocop.git).to receive(:renamed_files).and_return([])

            expect { @rubocop.lint }.not_to raise_error
          end
        end

        describe 'report to danger' do
          before do
            allow(@rubocop.git).to receive(:modified_files)
              .and_return(['spec/fixtures/ruby_file.rb'])
            allow(@rubocop.git).to receive(:added_files).and_return([])
            allow(@rubocop.git).to receive(:renamed_files).and_return([])
            allow(@rubocop).to receive(:`)
              .with('bundle exec rubocop -f json --only-recognized-file-types spec/fixtures/ruby_file.rb')
              .and_return(response_ruby_file)
          end

          it 'reports to danger' do
            fail_msg = %{spec/fixtures/ruby_file.rb | 13 | Don't do that!}
            expect(@rubocop).to receive(:fail).with(fail_msg)
            @rubocop.lint(report_danger: true)
          end

          it 'includes cop names when include_cop_names is set' do
            fail_msg = %{spec/fixtures/ruby_file.rb | 13 | Syntax/WhetherYouShouldDoThat: Don't do that!}

            expect(@rubocop).to receive(:fail).with(fail_msg)
            @rubocop.lint(report_danger: true, include_cop_names: true)
          end
        end
      end
    end
  end
end

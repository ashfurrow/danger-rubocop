require File.expand_path('../spec_helper', __FILE__)

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

      describe :lint_files do
        before do
          # Set up our stubbed JSON response
          response = {
            'files' => [
              {
                'path' => 'spec/fixtures/ruby_file.rb',
                'offenses' => [
                  {
                    'message' => "Don't do that!",
                    'location' => { 'line' => 13 }
                  }
                ]
              },
              {
                'path' => 'spec/fixtures/another_ruby_file.rb',
                'offenses' => [
                  {
                    'message' => "Don't do that!",
                    'location' => { 'line' => 23 }
                  }
                ]
              }
            ]
          }
          @rubocop_response = response.to_json
        end

        it 'handles a rubocop report for specified files' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json')
            .and_return(@rubocop_response)

          # Do it
          @rubocop.lint('spec/fixtures/ruby*.rb')

          output = @rubocop.status_report[:markdowns].first.message

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("spec/fixtures/ruby_file.rb | 13   | Don't do that!")
        end

        it 'handles a rubocop report for files changed in the PR' do
          allow(@rubocop.git).to receive(:added_files).and_return([])
          allow(@rubocop.git).to receive(:modified_files)
            .and_return(["spec/fixtures/another_ruby_file.rb"])

          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json')
            .and_return(@rubocop_response)

          @rubocop.lint

          output = @rubocop.status_report[:markdowns].first.message

          expect(output).to include('Rubocop violations')
          expect(output).to include("spec/fixtures/another_ruby_file.rb | 23   | Don't do that!")
        end

        it 'is formatted as a markdown table' do
          allow(@rubocop.git).to receive(:modified_files)
            .and_return(['spec/fixtures/ruby_file.rb'])
          allow(@rubocop.git).to receive(:added_files).and_return([])
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json')
            .and_return(@rubocop_response)

          @rubocop.lint

          formatted_table = <<-EOS
### Rubocop violations\n
| File                       | Line | Reason         |
|----------------------------|------|----------------|
| spec/fixtures/ruby_file.rb | 13   | Don't do that! |
EOS
          expect(@rubocop.status_report[:markdowns].first.message).to eq(formatted_table.chomp)
        end
      end
    end
  end
end

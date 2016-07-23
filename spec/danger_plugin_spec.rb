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
                'path' => 'ruby_file.rb',
                'offenses' => [
                  {
                    'message' => "Don't do that!",
                    'location' => { 'line' => 13 }
                  }
                ]
              }
            ]
          }
          @rubocop_response = response.to_json
        end

        it 'handles a known rubocop report' do
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json spec/fixtures/ruby_file.rb')
            .and_return(@rubocop_response)

          # Do it
          @rubocop.lint('spec/fixtures/*.rb')

          output = @rubocop.status_report[:markdowns].first

          expect(output).to_not be_empty

          # A title
          expect(output).to include('Rubocop violations')
          # A warning
          expect(output).to include("ruby_file.rb | 13   | Don't do that!")
        end

        it 'handles no files' do
          allow(@rubocop.git).to receive(:modified_files)
            .and_return(['spec/fixtures/ruby_file.rb'])
          allow(@rubocop.git).to receive(:added_files).and_return([])
          allow(@rubocop).to receive(:`)
            .with('bundle exec rubocop -f json spec/fixtures/ruby_file.rb')
            .and_return(@rubocop_response)

          @rubocop.lint

          expect(@rubocop.status_report[:markdowns].first).to_not be_empty
        end
      end
    end
  end
end

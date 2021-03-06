# frozen_string_literal: true

require 'csv'
require 'fileutils'
require 'octokit'
require 'tty-spinner'

require_relative 'util/authenticate'
require_relative 'util/check_rate_limit'

def get_workflows(token)
  repository_does_not_exists = 0
  client = authenticate(token)

  CSV.foreach('data/dataset_final.csv', headers: true) do |row|
    spinner = TTY::Spinner.new("[:spinner] Get #{row[0]} workflows ...", format: :classic)
    spinner.auto_spin

    begin
      client = authenticate(token)
      check_rate_limit(client, 0, spinner)

      if client.repository?(row[0]) # if repository exists
        workflows = client.contents(row[0], path: '.github/workflows')

        workflows.each do |workflow|
          next unless File.extname(workflow.name) == '.yml' or File.extname(workflow.name) == '.yaml' # next unless a workflow file

          client = authenticate(token)
          check_rate_limit(client, 10, spinner) # 10 call buffer
          commits = client.commits(row[0], path: ".github/workflows/#{workflow.name}")

          client = authenticate(token)
          check_rate_limit(client, commits.count, spinner)

          commits.reverse_each do |commit|
              dest = "data/workflows/#{row[0]}/#{workflow.rpartition('.')[0]}"
              date = "#{commit.commit.author.date.to_s.gsub(" ", "_").gsub(":", "-")}_#{workflow}"
              begin
                  file = client.contents(row[0], path: ".github/workflows/#{workflow}", ref: commit.sha)
              rescue StandardError # workflow file was deleted
                  FileUtils.mkdir_p dest unless File.exist?(dest)
                  File.open("#{dest}/#{date}", 'w') {|f| f.write('') }
                  next
              end
              enc = file.content
              plain = Base64.decode64(enc)
              FileUtils.mkdir_p dest unless File.exist?(dest)
              File.open("#{dest}/#{date}", 'w') {|f| f.write(plain) }
          end
        end
      else
        spinner.error
        repository_does_not_exists =+ 1
        next
      end
    rescue StandardError
      spinner.error
      next
    end

    spinner.success
  end
end

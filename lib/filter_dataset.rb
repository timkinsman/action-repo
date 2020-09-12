# frozen_string_literal: true

require 'csv'
require 'tty-spinner'

def filter_dataset(input, output)
  spinner = TTY::Spinner.new('[:spinner] Filtering dataset ...', format: :classic)
  spinner.auto_spin

  CSV.open(output, 'w') do |csv|
    CSV.foreach(input) do |row|
      csv << [row[0]] if row[13] == '1' || row[15] == '1'
    end
  end

  spinner.success
end
# frozen_string_literal: true

require 'csv'
require 'tty-spinner'

def rank_actions(dir, input, output)
  spinner = TTY::Spinner.new("[:spinner] Ranking actions ...", format: :classic)
  spinner.auto_spin

  nested_actions = []
  CSV.open(output, "w") do |csv|
    CSV.foreach(input).with_index do |row|
      actions = row[3].tr('[\'"]', '').tr('\\', '').split(', ')
      nested_actions << actions
    end
    nested_actions = nested_actions.flatten(1)
    to_hash = nested_actions.group_by(&:itself).transform_values(&:count)
    to_hash.each do |k,v|
      csv << [k, v] if !k.start_with?('./', '#')
    end
  end
  
  spinner.success
end

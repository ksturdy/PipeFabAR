#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get groups
main_group = project.main_group['PipeRouterAR']
utilities_group = main_group['Utilities']
components_group = main_group['Views']['Components']

# Add the three new files
new_files = {
  'Theme.swift' => utilities_group,
  'QRCodeGenerator.swift' => utilities_group,
  'BrandingView.swift' => components_group
}

new_files.each do |filename, group|
  existing = group.files.find { |f| f.path == filename }
  if existing.nil?
    file_ref = group.new_reference(filename)
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added: #{filename}"
  else
    puts "Already exists: #{filename}"
  end
end

project.save
puts "\nNew files added successfully!"

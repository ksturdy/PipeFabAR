#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Remove the incorrectly added files
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    if item.real_path.to_s.include?('PipeRouterAR/PipeRouterAR/')
      puts "Removing incorrectly referenced: #{item.path}"
      item.remove_from_project
    end
  end
end

# Get the main target
target = project.targets.first

# Navigate to the correct groups
main_group = project.main_group['PipeRouterAR']
utilities_group = main_group['Utilities']
views_group = main_group['Views']

# Create Components group if it doesn't exist
components_group = views_group['Components']
if components_group.nil?
  components_group = views_group.new_group('Components')
end

# Add files with correct paths (relative to the group)
files = {
  'Theme.swift' => utilities_group,
  'QRCodeGenerator.swift' => utilities_group,
  'BrandingView.swift' => components_group
}

files.each do |filename, group|
  # Check if already exists
  existing = group.files.find { |f| f.path == filename }
  next if existing
  
  # Add file reference with just the filename (relative to group)
  file_ref = group.new_reference(filename)
  
  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{filename} to #{group.hierarchy_path}"
end

project.save
puts "\nProject fixed successfully!"

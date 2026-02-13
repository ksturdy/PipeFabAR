#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get or create groups
utilities_group = project.main_group.find_subpath('PipeRouterAR/Utilities', true)
components_group = project.main_group.find_subpath('PipeRouterAR/Views/Components', true)

# Files to add
files_to_add = [
  { path: 'PipeRouterAR/Utilities/Theme.swift', group: utilities_group },
  { path: 'PipeRouterAR/Utilities/QRCodeGenerator.swift', group: utilities_group },
  { path: 'PipeRouterAR/Views/Components/BrandingView.swift', group: components_group }
]

files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  
  # Check if file already exists in project
  existing = group.files.find { |f| f.path == File.basename(file_path) }
  next if existing
  
  # Add file reference
  file_ref = group.new_reference(file_path)
  
  # Add to target
  target.add_file_references([file_ref])
end

project.save
puts "Files added successfully!"

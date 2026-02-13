#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Components group
components_group = project.main_group['PipeRouterAR']['Views']['Components']

if components_group
  puts "Components group found"
  puts "Current path: #{components_group.path}"
  puts "Source tree: #{components_group.source_tree}"
  
  # Set the proper path
  components_group.path = 'Components'
  components_group.source_tree = '<group>'
  
  puts "Updated path: #{components_group.path}"
  
  project.save
  puts "\nComponents group path fixed!"
else
  puts "Components group not found!"
end

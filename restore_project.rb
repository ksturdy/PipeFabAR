#!/usr/bin/env ruby
require 'xcodeproj'
require 'find'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get or create the main group structure
main_group = project.main_group['PipeRouterAR']
if main_group.nil?
  main_group = project.main_group.new_group('PipeRouterAR')
end

# Define all the directories we need
groups = {
  'Models' => [],
  'Views' => [],
  'Views/Projects' => [],
  'Views/Spools' => [],
  'Views/WorkPackages' => [],
  'Views/Settings' => [],
  'Views/Components' => [],
  'Services' => [],
  'Managers' => [],
  'Utilities' => [],
  'Utilities/Extensions' => []
}

# Create group hierarchy
groups_refs = {}
groups.keys.each do |path|
  parts = path.split('/')
  parent = main_group
  current_path = []
  
  parts.each do |part|
    current_path << part
    full_path = current_path.join('/')
    
    existing = parent[part]
    if existing.nil?
      groups_refs[full_path] = parent.new_group(part)
      parent = groups_refs[full_path]
    else
      groups_refs[full_path] = existing
      parent = existing
    end
  end
end

# Find all Swift files in the project directory
swift_files = []
Find.find('PipeRouterAR') do |path|
  next if path =~ /\/(build|\.build|DerivedData|xcuserdata)\//
  next unless path.end_with?('.swift')
  swift_files << path
end

# Add each file to the appropriate group
swift_files.each do |file_path|
  relative_path = file_path.sub('PipeRouterAR/', '')
  filename = File.basename(file_path)
  dir = File.dirname(relative_path)
  dir = '' if dir == '.'
  
  # Find the right group
  group = nil
  if dir == ''
    group = main_group
  else
    group = groups_refs[dir] || main_group
  end
  
  # Check if file already exists
  existing = group.files.find { |f| f.path == filename }
  next if existing
  
  # Add file
  file_ref = group.new_reference(filename)
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added: #{relative_path}"
end

# Add assets and Info.plist (not to build phase)
assets_ref = main_group.new_reference('Assets.xcassets')
info_ref = main_group.new_reference('Info.plist')
puts "Added: Assets.xcassets"
puts "Added: Info.plist"

project.save
puts "\nProject restored successfully!"

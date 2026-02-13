#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PipeRouterAR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find Assets.xcassets reference
assets_ref = project.main_group['PipeRouterAR'].files.find { |f| f.path == 'Assets.xcassets' }

if assets_ref
  puts "Found Assets.xcassets reference"
  
  # Check if already in resources
  existing = target.resources_build_phase.files.find { |f| f.file_ref == assets_ref }
  
  if existing
    puts "Assets.xcassets already in resources build phase"
  else
    # Add to resources build phase
    target.resources_build_phase.add_file_reference(assets_ref)
    puts "Added Assets.xcassets to Resources build phase"
  end
  
  project.save
  puts "Project saved successfully!"
else
  puts "ERROR: Could not find Assets.xcassets file reference"
end

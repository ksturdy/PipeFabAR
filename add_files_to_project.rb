#!/usr/bin/env ruby
#
# Script to add new Swift files to PipeFabAR Xcode project
# This uses the xcodeproj gem to safely modify the project file
#

require 'xcodeproj'

PROJECT_PATH = 'PipeFabAR.xcodeproj'
TARGET_NAME = 'PipeFabAR'

# Files to add (relative to project root)
FILES_TO_ADD = {
  'Models' => [
    'PipeFabAR/Models/PipeDimensions.swift',
    'PipeFabAR/Models/FittingDimensions.swift',
    'PipeFabAR/Models/FlangeDimensions.swift',
    'PipeFabAR/Models/ValveDimensions.swift',
    'PipeFabAR/Models/CustomDimensionOverride.swift'
  ],
  'Utilities' => [
    'PipeFabAR/Utilities/IsometricRenderer.swift'
  ],
  'Views/Components' => [
    'PipeFabAR/Views/Components/IsometricFittingShapes.swift',
    'PipeFabAR/Views/Components/PipeSegmentDetailView.swift'
  ]
}

puts "🔧 Adding files to #{PROJECT_PATH}..."

# Open the project
project = Xcodeproj::Project.open(PROJECT_PATH)

# Get the main target
target = project.targets.find { |t| t.name == TARGET_NAME }

unless target
  puts "❌ Error: Could not find target '#{TARGET_NAME}'"
  exit 1
end

# Track if any files were added
files_added = 0

FILES_TO_ADD.each do |group_name, files|
  files.each do |file_path|
    # Check if file exists on disk
    unless File.exist?(file_path)
      puts "⚠️  Skipping #{file_path} - file not found"
      next
    end

    # Check if file is already in project
    existing_file = project.files.find { |f| f.path == file_path }
    if existing_file
      puts "⏭️  Skipping #{File.basename(file_path)} - already in project"
      next
    end

    # Find the appropriate group
    group_path = group_name.split('/')
    group = project.main_group
    group_path.each do |path_component|
      group = group.groups.find { |g| g.name == path_component || g.path == path_component }
      unless group
        puts "⚠️  Warning: Could not find group '#{group_name}', using root"
        group = project.main_group
        break
      end
    end

    # Add file reference to the group
    file_ref = group.new_reference(file_path)

    # Add to target's sources build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "✅ Added #{File.basename(file_path)} to #{group_name}"
    files_added += 1
  end
end

if files_added > 0
  # Save the project
  project.save
  puts "\n🎉 Successfully added #{files_added} file(s) to the project!"
  puts "✨ You can now build the project in Xcode"
else
  puts "\n✋ No files were added (all files already in project)"
end

#!/usr/bin/env ruby
# Adds the MisiCopyRemote iOS target to MisiCopy.xcodeproj.
# Idempotent: skips work that is already done.

$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/xcodeproj-1.27.0/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/claide-1.1.0/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/colored2-3.1.2/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/atomos-0.1.3/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/nanaimo-0.4.0/lib"

require 'xcodeproj'

PROJECT_PATH = '/Users/matthieumisiraca/Desktop/MisiCopy/MisiCopy.xcodeproj'
TARGET_NAME = 'MisiCopyRemote'
BUNDLE_ID = 'fr.misilab.MisiCopyRemote'
REMOTE_DIR = '/Users/matthieumisiraca/Desktop/MisiCopy/MisiCopyRemote'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Skip if target already exists.
if project.targets.find { |t| t.name == TARGET_NAME }
  puts "Target #{TARGET_NAME} already exists — nothing to do."
  exit 0
end

# 1. Create the iOS app target.
target = project.new_target(
  :application,
  TARGET_NAME,
  :ios,
  '17.0',
  project.products_group,
  :swift
)

# 2. Configure build settings.
target.build_configurations.each do |config|
  bs = config.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  bs['PRODUCT_NAME'] = TARGET_NAME
  bs['INFOPLIST_FILE'] = 'MisiCopyRemote/Info.plist'
  bs['DEVELOPMENT_TEAM'] = 'SM6L2XLUBA'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1'  # iPhone only
  bs['MARKETING_VERSION'] = '1.0.0'
  bs['CURRENT_PROJECT_VERSION'] = '1'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  bs['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  bs['ENABLE_PREVIEWS'] = 'YES'
  bs['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  bs['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
  bs['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
  bs['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
end

# 3. Create the MisiCopyRemote group at project root.
remote_group = project.main_group.new_group(TARGET_NAME, 'MisiCopyRemote')

# Helper that recursively adds source files and resources.
def add_directory(group, directory, target)
  Dir.entries(directory).sort.each do |entry|
    next if entry.start_with?('.')
    full = File.join(directory, entry)
    if File.directory?(full)
      subgroup = group.new_group(entry, entry)
      add_directory(subgroup, full, target)
    else
      next if entry == 'README.md' # not needed inside the app bundle
      file_ref = group.new_file(full)
      if entry.end_with?('.swift')
        target.add_file_references([file_ref])
      elsif entry == 'Info.plist'
        # Don't add Info.plist to a build phase — it's referenced via build settings.
      else
        target.add_resources([file_ref])
      end
    end
  end
end

add_directory(remote_group, REMOTE_DIR, target)

# 4. Share the cross-platform models with the new target.
shared_models = [
  'MisiCopy/Models/SessionSnapshot.swift',
  'MisiCopy/Models/PairingPayload.swift'
]
shared_models.each do |relative|
  ref = project.files.find { |f| f.path == relative }
  if ref
    target.source_build_phase.add_file_reference(ref, true)
    puts "  shared model added: #{relative}"
  else
    puts "  WARN: could not find shared model #{relative}"
  end
end

# 5. Add a matching scheme so the user can immediately ⌘R.
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)

project.save
puts "Added target #{TARGET_NAME} with #{target.source_build_phase.files.count} sources."

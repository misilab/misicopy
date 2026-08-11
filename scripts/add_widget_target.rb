#!/usr/bin/env ruby
# Adds the MisiCopyWidgets Widget Extension target to MisiCopy.xcodeproj.
# Hosts the Live Activity used by the iPhone Remote dashboard.
# Idempotent: skips work that is already done.

$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/xcodeproj-1.27.0/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/claide-1.1.0/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/colored2-3.1.2/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/atomos-0.1.3/lib"
$LOAD_PATH.unshift "/Users/matthieumisiraca/.gem/ruby/2.6.0/gems/nanaimo-0.4.0/lib"

require 'xcodeproj'

PROJECT_PATH = '/Users/matthieumisiraca/Desktop/MisiCopy/MisiCopy.xcodeproj'
TARGET_NAME = 'MisiCopyWidgets'
BUNDLE_ID = 'fr.misilab.MisiCopyRemote.LiveActivity'
WIDGETS_DIR = '/Users/matthieumisiraca/Desktop/MisiCopy/MisiCopyWidgets'
HOST_APP_NAME = 'MisiCopyRemote'

project = Xcodeproj::Project.open(PROJECT_PATH)

# Skip if target already exists.
if project.targets.find { |t| t.name == TARGET_NAME }
  puts "Target #{TARGET_NAME} already exists — nothing to do."
  exit 0
end

host_app = project.targets.find { |t| t.name == HOST_APP_NAME }
unless host_app
  abort "Host target #{HOST_APP_NAME} not found — run add_ios_target.rb first."
end

# 1. Create the app extension target.
target = project.new_target(
  :app_extension,
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
  bs['INFOPLIST_FILE'] = 'MisiCopyWidgets/Info.plist'
  bs['DEVELOPMENT_TEAM'] = 'SM6L2XLUBA'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1'  # iPhone only
  bs['MARKETING_VERSION'] = '1.1.0'
  bs['CURRENT_PROJECT_VERSION'] = '5'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['SKIP_INSTALL'] = 'YES'
  bs['ENABLE_PREVIEWS'] = 'YES'
  bs['SWIFT_APPROACHABLE_CONCURRENCY'] = 'YES'
  bs['SWIFT_DEFAULT_ACTOR_ISOLATION'] = 'MainActor'
  bs['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  bs['CODE_SIGN_ENTITLEMENTS'] = ''
  bs['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
end

# 3. Create the MisiCopyWidgets group at project root and add every Swift
#    file under MisiCopyWidgets/ to the build phase. Info.plist is excluded
#    — it's referenced via the INFOPLIST_FILE build setting, not as a
#    source.
widgets_group = project.main_group.new_group(TARGET_NAME, 'MisiCopyWidgets')
Dir.entries(WIDGETS_DIR).sort.each do |entry|
  next if entry.start_with?('.')
  full = File.join(WIDGETS_DIR, entry)
  next if File.directory?(full)
  next if entry == 'Info.plist'  # not a source nor a resource
  file_ref = widgets_group.new_file(full)
  if entry.end_with?('.swift')
    target.add_file_references([file_ref])
  end
end

# 4. Add the widget as an embedded extension of the iPhone app. This
#    creates the "Embed App Extensions" copy-files phase Xcode uses to
#    drop the .appex into the host app bundle at build time.
embed_phase = host_app.copy_files_build_phases.find do |phase|
  phase.symbol_dst_subfolder_spec == :plug_ins
end
embed_phase ||= host_app.new_copy_files_build_phase('Embed App Extensions').tap do |phase|
  phase.symbol_dst_subfolder_spec = :plug_ins
end
unless embed_phase.files_references.include?(target.product_reference)
  build_file = embed_phase.add_file_reference(target.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# 5. Make the iPhone app depend on the widget so building MisiCopyRemote
#    automatically rebuilds (and stapls) MisiCopyWidgets.
host_app.add_dependency(target)

# 6. Add a scheme so the user can build / preview the widget directly.
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)

project.save
puts "Added target #{TARGET_NAME} with #{target.source_build_phase.files.count} sources."
puts "Embedded into #{HOST_APP_NAME}."

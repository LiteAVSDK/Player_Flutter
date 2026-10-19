#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_super_player.podspec` to validate before publishing.

require 'yaml'

ALLOWED_VERSIONS = ['player', 'professional', 'premium', 'professional_premium']

# Default underlying SDK version when used standalone; overridable via LITEAV_SDK_VERSION (x.x.x).
sdk_version = ENV['LITEAV_SDK_VERSION'] || '13.5.21355'
unless sdk_version =~ /^\d+\.\d+\.\d+$/
  sdk_version = '13.5.21355'
end
puts "[SuperPlayer] sdk_version not specified, use default: #{sdk_version}" if ENV['LITEAV_SDK_VERSION'].nil?

env_sub_spec = ENV['LITEAV_SDK_SUB_SPEC']
if env_sub_spec && !ALLOWED_VERSIONS.include?(env_sub_spec)
  env_sub_spec = nil
end

# Locate host pubspec.yaml. Priority:
#   1. FLUTTER_APPLICATION_PATH env (flutter tool / CI)
#   2. flutter_application_path declared in host Podfile (add-to-app standard)
#   3. walk up from the Podfile directory (standard single-app)
#   4. walk down: a child dir that has both pubspec.yaml and ios/ (mixed project)
project_root = nil
pubspec_path = nil

if ENV['FLUTTER_APPLICATION_PATH']
  candidate = File.join(ENV['FLUTTER_APPLICATION_PATH'], 'pubspec.yaml')
  if File.exist?(candidate)
    project_root = ENV['FLUTTER_APPLICATION_PATH']
    pubspec_path = candidate
  end
end

if pubspec_path.nil? && defined?(Pod::Config)
  podfile = Pod::Config.instance.podfile
  podfile_path = (podfile.defined_in_file.to_s rescue nil) if podfile.respond_to?(:defined_in_file)
  if podfile_path && File.exist?(podfile_path)
    content = File.read(podfile_path) rescue nil
    if content && (m = content.match(/flutter_application_path\s*=\s*['"]([^'"]+)['"]/))
      base = File.dirname(podfile_path)
      candidate = File.expand_path(File.join(m[1], 'pubspec.yaml'), base)
      if File.exist?(candidate)
        project_root = File.dirname(candidate)
        pubspec_path = candidate
      end
    end
  end
end

if pubspec_path.nil? && defined?(Pod::Config)
  dir = Pod::Config.instance.project_root.to_s
  6.times do
    candidate = File.join(dir, 'pubspec.yaml')
    if File.exist?(candidate)
      project_root = dir
      pubspec_path = candidate
      break
    end
    parent = File.dirname(dir)
    break if parent == dir
    dir = parent
  end
end

if pubspec_path.nil? && defined?(Pod::Config)
  roots = [File.expand_path('..', Pod::Config.instance.project_root.to_s)]
  skip = ['.git', '.idea', '.dart_tool', 'build', 'node_modules', 'Pods', '.pub-cache', 'android', 'ios']
  depth = 0
  while depth < 4 && !roots.empty? && pubspec_path.nil?
    next_roots = []
    roots.each do |d|
      children = begin
        Dir.children(d)
      rescue
        next
      end
      children.each do |name|
        full = File.join(d, name)
        next unless File.directory?(full)
        next if skip.include?(name)
        if File.exist?(File.join(full, 'pubspec.yaml')) && File.exist?(File.join(full, '.flutter-plugins-dependencies'))
          project_root = full
          pubspec_path = File.join(full, 'pubspec.yaml')
          break
        end
        next_roots << full
      end
      break if pubspec_path
    end
    roots = next_roots
    depth += 1
  end
end

sub_spec_version = nil

# Follow tencent_rtc_sdk when the host integrates it: bare default subspec + versionless deps,
# series/version are then decided by rtc_sdk's targeted subspec dependency.
# NOTE: top-level def does not work here (podspec is eval'ed inside module Pod).
integrated_with_rtc = begin
  result = false
  if project_root && ENV['USE_LOCAL_LITEAV_SDK'] != 'TRUE'
    lock_path = File.join(project_root, 'pubspec.lock')
    if File.exist?(lock_path)
      result = true if File.read(lock_path).match?(/^  tencent_rtc_sdk:$/)
    end
    unless result
      yaml_path = File.join(project_root, 'pubspec.yaml')
      result = true if File.exist?(yaml_path) && File.read(yaml_path).match?(/^dependencies:\s*$.*?^  tencent_rtc_sdk:/m)
    end
  end
  result
end
if integrated_with_rtc
  # bare has no underlying dep; series/version come from rtc_sdk's targeted subspec dependency.
  sub_spec_version = 'bare'
elsif env_sub_spec
  sub_spec_version = env_sub_spec
elsif sub_spec_version.nil? && pubspec_path && File.exist?(pubspec_path)
  begin
    pubspec = YAML.load_file(pubspec_path)
    if pubspec['super_player'] && pubspec['super_player']['sub_spec']
        parsed_version = pubspec['super_player']['sub_spec']
        if ALLOWED_VERSIONS.include?(parsed_version)
            sub_spec_version = parsed_version
          else
            sub_spec_version = 'professional'
        end
    end
  rescue
  end
end
puts "[SuperPlayer] sub_spec not specified, use default: professional" if sub_spec_version.nil?
sub_spec_version ||= 'professional'
puts "[SuperPlayer] sub_spec: #{sub_spec_version}, sdk_version: #{sdk_version}"

Pod::Spec.new do |s|
  s.name             = 'super_player'
  s.version = '13.5.1'
  s.summary          = 'The super_player Flutter plugin is one of the sub-product SDKs of the audio/video terminal SDK (Tencent Cloud Video on Demand).'
  s.description      = <<-DESC
player plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => './LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.framework = ['MobileCoreServices']
  s.platform = :ios, '12.0'
  s.static_framework = true
  s.resources = ['Classes/TXResource/**/*']

  s.default_subspec = sub_spec_version

  # versionless when tencent_rtc_sdk integrated (intersection resolves to rtc_sdk's constraint).

  # Empty default subspec used when rtc_sdk is integrated; series comes from rtc_sdk.
   s.subspec 'bare' do |ss|
   end

   s.subspec 'player' do |ss|
       integrated_with_rtc ? ss.dependency('TXLiteAVSDK_Player') : ss.dependency('TXLiteAVSDK_Player', sdk_version)
   end

   s.subspec 'professional' do |ss|
       integrated_with_rtc ? ss.dependency('TXLiteAVSDK_Professional') : ss.dependency('TXLiteAVSDK_Professional', sdk_version)
   end

    s.subspec 'premium' do |ss|
       integrated_with_rtc ? ss.dependency('TXLiteAVSDK_Player_Premium') : ss.dependency('TXLiteAVSDK_Player_Premium', sdk_version)
    end

   s.subspec 'professional_premium' do |ss|
       integrated_with_rtc ? ss.dependency('TXLiteAVSDK_Professional_Player_Premium') : ss.dependency('TXLiteAVSDK_Professional_Player_Premium', sdk_version)
   end

#   s.dependency 'FTXPiPKit'
  s.vendored_frameworks = [
    'localdep/FTXPiPKit.xcframework'
  ]

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

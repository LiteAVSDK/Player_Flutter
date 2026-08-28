#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_super_player.podspec` to validate before publishing.

require 'yaml'

ALLOWED_VERSIONS = ['player', 'professional', 'premium', 'professional_premium']

# Default underlying SDK version when used standalone; overridable via LITEAV_SDK_VERSION (x.x.x).
sdk_version = ENV['LITEAV_SDK_VERSION'] || '13.4.21067'
unless sdk_version =~ /^\d+\.\d+\.\d+$/
  puts "[SuperPlayer] warning: invalid LITEAV_SDK_VERSION '#{sdk_version}' (expect x.x.x), fallback to default"
  sdk_version = '13.3.20845'
end

env_sub_spec = ENV['LITEAV_SDK_SUB_SPEC']
if env_sub_spec && !ALLOWED_VERSIONS.include?(env_sub_spec)
  puts "[SuperPlayer] warning: invalid LITEAV_SDK_SUB_SPEC '#{env_sub_spec}', allowed: #{ALLOWED_VERSIONS.join(', ')}"
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
    puts "[SuperPlayer] host pubspec found (FLUTTER_APPLICATION_PATH): #{pubspec_path}"
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
        puts "[SuperPlayer] host pubspec found (Podfile flutter_application_path): #{pubspec_path}"
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
      puts "[SuperPlayer] host pubspec found (ancestor): #{pubspec_path}"
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
          puts "[SuperPlayer] host pubspec found (child): #{pubspec_path}"
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

puts "[SuperPlayer] project_root: #{project_root}"
puts "[SuperPlayer] warning: pubspec.yaml not found" if pubspec_path.nil?

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
puts "[SuperPlayer] integrated with tencent_rtc_sdk: #{integrated_with_rtc}"

puts "---------------- [SuperPlayer] ----------------"
if integrated_with_rtc
  # bare has no underlying dep; series/version come from rtc_sdk's targeted subspec dependency.
  sub_spec_version = 'bare'
  puts "[SuperPlayer] default_subspec = bare (series decided by tencent_rtc_sdk)"
elsif env_sub_spec
  sub_spec_version = env_sub_spec
  puts "[SuperPlayer] sub_spec from LITEAV_SDK_SUB_SPEC: #{sub_spec_version}"
elsif sub_spec_version.nil? && pubspec_path && File.exist?(pubspec_path)
  begin
      puts "[SuperPlayer] path: #{pubspec_path}"
    pubspec = YAML.load_file(pubspec_path)
    if pubspec['super_player'] && pubspec['super_player']['sub_spec']
        parsed_version = pubspec['super_player']['sub_spec']
        if ALLOWED_VERSIONS.include?(parsed_version)
            sub_spec_version = parsed_version
            puts "[SuperPlayer] parsed success: #{sub_spec_version}"
          else
            sub_spec_version = 'professional'
            puts "[SuperPlayer] warning: invalid sub_spec '#{parsed_version}', allowed: #{ALLOWED_VERSIONS.join(', ')}"
            puts "[SuperPlayer] fallback to default: #{sub_spec_version}"
        end
    else
      puts "[SuperPlayer] sub_spec not found，use default"
    end
  rescue => e
    puts "[SuperPlayer] YAML parsed error: #{e.message}"
  end
else
  puts "[SuperPlayer] warning: pubspec.yaml not found (path: #{pubspec_path})"
end
puts "-----------------------------------------------"

Pod::Spec.new do |s|
  s.name             = 'super_player'
  s.version = '13.3.0'
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

  # Set the dependent LiteAV SDK type:
  # Player SDK: s.dependency 'TXLiteAVSDK_Player'
  # Player_Premium SDK: s.dependency 'TXLiteAVSDK_Player_Premium'
  # Professional SDK:  s.dependency 'TXLiteAVSDK_Professional'
  # If you want to specify the SDK version（eg 11.6.15041), use:  s.dependency 'TXLiteAVSDK_Player','11.6.15041'
   s.subspec 'player' do |ss|
       ss.dependency 'TXLiteAVSDK_Player', sdk_version
   end

   s.subspec 'professional' do |ss|
        ss.dependency 'TXLiteAVSDK_Professional', sdk_version
   end

    s.subspec 'premium' do |ss|
          ss.dependency 'TXLiteAVSDK_Player_Premium', sdk_version
    end

   s.subspec 'professional_premium' do |ss|
         ss.dependency 'TXLiteAVSDK_Professional_Player_Premium', sdk_version
   end

#   s.dependency 'FTXPiPKit'
  s.vendored_frameworks = [
    'localdep/FTXPiPKit.xcframework'
  ]

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

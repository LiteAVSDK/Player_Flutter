#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_super_player.podspec` to validate before publishing.

require 'yaml'

project_root = ENV['FLUTTER_APPLICATION_PATH']

if project_root.nil? && defined?(Pod::Config)
  podfile_dir = Pod::Config.instance.project_root.to_s
  project_root = File.expand_path('..', podfile_dir)
end

puts "[SuperPlayer] project_root: #{project_root}"
pubspec_path = File.join(project_root, 'pubspec.yaml') if project_root

ALLOWED_VERSIONS = ['player', 'professional', 'premium', 'professional_premium']

# Default underlying SDK version when used standalone.
sdk_version = '13.4.21067'

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
elsif sub_spec_version.nil?
  puts "[SuperPlayer] warning: pubspec.yaml not found (path: #{pubspec_path})"
end
sub_spec_version ||= 'professional'
puts "[SuperPlayer] final sub_spec: #{sub_spec_version}, sdk_version: #{sdk_version}"
puts "-----------------------------------------------"

Pod::Spec.new do |s|
  s.name             = 'super_player'
  s.version = '13.4.1'
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

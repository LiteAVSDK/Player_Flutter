#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_super_player.podspec` to validate before publishing.

require 'yaml'

project_root = ENV['FLUTTER_APPLICATION_PATH']

# 利用 CocoaPods 的 Config 实例找到 Podfile 所在的目录，宿主项目通常在 Podfile 的上一级
if project_root.nil? && defined?(Pod::Config)
  podfile_dir = Pod::Config.instance.project_root.to_s
  project_root = File.expand_path('..', podfile_dir)
end

puts "[SuperPlayer] project_root: #{project_root}"
pubspec_path = File.join(project_root, 'pubspec.yaml') if project_root

sdk_version = '13.0.20275'
sub_spec_version = 'professional'
ALLOWED_VERSIONS = ['player', 'professional', 'premium', 'professional_premium']

puts "---------------- [SuperPlayer] ----------------"
if File.exist?(pubspec_path)
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
  s.version = '13.0.1'
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

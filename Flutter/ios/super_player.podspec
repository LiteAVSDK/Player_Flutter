#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_super_player.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'super_player'
  s.version = '12.8.0'
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

  # Set the dependent LiteAV SDK type:
  # Player SDK: s.dependency 'TXLiteAVSDK_Player'
  # Player_Premium SDK: s.dependency 'TXLiteAVSDK_Player_Premium'
  # Professional SDK:  s.dependency 'TXLiteAVSDK_Professional'
  # If you want to specify the SDK version（eg 11.6.15041), use:  s.dependency 'TXLiteAVSDK_Player','11.6.15041'
  s.dependency 'TXLiteAVSDK_Professional','12.8.19666'
  # s.dependency 'FTXPiPKit'
  s.vendored_frameworks = [
    'localdep/FTXPiPKit.xcframework'
  ]

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end

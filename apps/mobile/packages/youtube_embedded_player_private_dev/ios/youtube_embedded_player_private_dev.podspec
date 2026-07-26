Pod::Spec.new do |spec|
  spec.name             = 'youtube_embedded_player_private_dev'
  spec.version          = '0.0.1'
  spec.summary          = 'Private-Dev official YouTube embedded-player host.'
  spec.description      = <<-DESC
An isolated debug-only WKWebView platform adapter for the provider-owned
YouTube IFrame player document.
                       DESC
  spec.homepage         = 'https://moolsocial.com'
  spec.license          = { :type => 'Proprietary', :file => '../LICENSE' }
  spec.author           = { 'MoolSocial' => 'hello@moolsocial.com' }
  spec.source           = { :path => '.' }
  spec.source_files     = 'Classes/**/*'
  spec.dependency 'Flutter'
  spec.platform = :ios, '15.0'
  spec.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  spec.swift_version = '5.0'
  spec.frameworks = 'CryptoKit', 'Security', 'WebKit'
end

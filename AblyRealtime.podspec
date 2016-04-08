Pod::Spec.new do |s|
  s.name              = "AblyRealtime"
  s.version           = "0.8.0"
  s.summary           = "iOS client for Ably"
  s.description       = <<-DESC
                        iOS client library for ably.io, the realtime messaging service, written in Objective-C and ready for Swift 2.0.
                        DESC
  s.homepage          = "https://www.ably.io"
  s.license           = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author            = { "Ably" => "support@ably.io" }
  s.source            = { :git => "https://github.com/ably/ably-ios.git", :tag => s.version.to_s }
  s.requires_arc      = true
  s.social_media_url  = 'https://twitter.com/ablyrealtime'
  s.documentation_url = "https://www.ably.io/documentation"
  s.platform          = :ios, '8.0'
  s.requires_arc      = true
  s.source_files      = 'Source/*.{h,m}'
  s.module_map        = 'Source/AblyRealtime.modulemap'
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$CONFIGURATION_BUILD_DIR/SwiftWebSocket.framework/Headers' }
  s.dependency 'SwiftWebSocket', '~> 2.5'
end

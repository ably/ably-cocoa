Pod::Spec.new do |s|
  s.name              = "Ably"
  s.version           = `Scripts/get-version.sh`
  s.summary           = "iOS client for Ably"
  s.description       = <<-DESC
                        iOS client library for ably.io, the realtime messaging service, written in Objective-C and ready for Swift 3.0.
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
  s.module_map        = 'Source/Ably.modulemap'
  s.dependency 'SocketRocket', '0.5.1'
  s.dependency 'msgpack', '0.1.8'
  s.dependency 'KSCrashAblyFork', '1.15.8-ably-1'
  s.dependency 'ULID', '1.0.2'
end

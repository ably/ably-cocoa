Pod::Spec.new do |s|
  s.name              = "Ably"
  s.version           = `Scripts/get-version.sh`
  s.summary           = "iOS, tvOS and macOS Objective-C and Swift client for Ably"
  s.description       = <<-DESC
                        iOS, tvOS and macOS Objective-C and Swift client library for ably.io, the realtime messaging service.
                        DESC
  s.homepage          = "https://www.ably.io"
  s.license           = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author            = { "Ably" => "support@ably.io" }
  s.source            = { :git => "https://github.com/ably/ably-cocoa.git", :tag => s.version.to_s }
  s.social_media_url  = 'https://twitter.com/ablyrealtime'
  s.documentation_url = "https://www.ably.io/documentation"
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.11'
  s.requires_arc      = true
  s.swift_version     = '5.0'
  s.source_files      = 'Source/**/*.{h,m,swift}'
  s.private_header_files = 'Source/*+Private.h', 'Source/Private/*.h'
  s.module_map        = 'Source/Ably.modulemap'
  s.dependency 'SocketRocketAblyFork', '0.5.2-ably-4'
  s.dependency 'KSCrashAblyFork', '1.15.20-ably-5'
  s.dependency 'msgpack', '0.3.1'
  s.dependency 'ULID', '1.1.0'
  s.dependency 'SAMKeychain', '1.5.3'
end

Pod::Spec.new do |s|
  s.name                    = "Ably"
  s.version                 = `Scripts/get-version.sh`
  s.summary                 = "iOS, tvOS and macOS Objective-C and Swift client for Ably"
  s.description             = <<-DESC
                              iOS, tvOS and macOS Objective-C and Swift client library for ably.com, the realtime messaging service.
                              DESC
  s.homepage                = "https://www.ably.com"
  s.license                 = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author                  = { "Ably" => "support@ably.com" }
  s.source                  = { :git => "https://github.com/ably/ably-cocoa.git", :tag => s.version.to_s }
  s.social_media_url        = 'https://twitter.com/ablyrealtime'
  s.documentation_url       = "https://www.ably.io/documentation"
  s.ios.deployment_target   = '10.0'
  s.tvos.deployment_target  = '10.0'
  s.osx.deployment_target   = '10.12'
  s.requires_arc            = true
  s.swift_version           = '5.0'
  s.source_files            = 'Source/**/*.{h,m,swift}'
  s.resource_bundles        = {'Ably' => ['Source/PrivacyInfo.xcprivacy']}
  s.private_header_files    = 'Source/PrivateHeaders/**/*.h', 'Source/SocketRocket/**/*.h'
  s.module_map              = 'Source/Ably.modulemap'
  # This is for the import of `APLiveObjectsPlugin.h` to resolve. Copied from:
  # - https://stackoverflow.com/questions/28425765/add-a-user-header-search-path-to-a-podspec
  # - https://stackoverflow.com/questions/58690010/including-a-directory-as-a-search-path-during-compilation-with-cocoapods
  s.pod_target_xcconfig     = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/AblyPlugin/include"'
  }
  s.dependency 'msgpack', '0.4.0'
  s.dependency 'AblyDeltaCodec', '1.3.3'
end

#
# Be sure to run `pod lib lint ably.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ably"
  s.version          = "0.7.0"
  s.summary          = "iOS client for Ably: A highly scalable, superfast and secure hosted real-time messaging service"
  s.homepage         = "https://www.ably.io"
  s.license          = 'MIT'
  s.author           = { "Vic Zaccarelli" => "victorzaccarelli@gmail.com" }
  s.source           = { :git => "https://github.com/ably/ably-ios.git", :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'ably-ios/*.{h,m}'
  s.dependency 'SocketRocket', '~> 0.3.1-beta2'
end

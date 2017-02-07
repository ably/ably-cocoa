platform :ios, '8.0'
use_frameworks!
podspec :path => 'Ably.podspec'

def project_pods
    pod 'SocketRocket', '0.5.1'
    pod 'msgpack', '0.1.8'
    pod 'KSCrashAblyFork', '1.15.8-ably-1'
    pod 'ULID', '1.0.2'
end

def test_pods
    project_pods
    pod 'Quick', '1.1.0'
    pod 'Nimble', '7.0.0'
    # Helpers
    pod 'Aspects'
    pod 'SwiftyJSON', '3.1.4'
end

target 'Ably' do
    project_pods
end

target 'AblySpec' do
    test_pods
end

platform :ios, '8.0'
use_frameworks!
podspec :path => 'Ably.podspec'

def project_pods
    pod 'SocketRocket', '0.5.1'
    pod 'msgpack', '0.1.8'
end

def test_pods
    project_pods
    pod 'Quick', '0.9.3'
    pod 'Nimble', '4.1.0'
    # Helpers
    pod 'Aspects'
    pod 'SwiftyJSON', '2.4.0'
end

target 'Ably' do
    project_pods
end

target 'AblySpec' do
    test_pods
end

target 'AblyTests' do
    test_pods
end

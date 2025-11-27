import Ably
import Nimble
import XCTest

class ARTDomainSelectorTests: XCTestCase {
    
    // MARK: - REC1: Primary Domain Tests
    
    // REC1a: Default case
    func test__001__ARTDomainSelector__primaryDomain__should_return_default_domain_when_endpoint_is_nil() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "main.realtime.ably.net")
    }
    
    // REC1b2: Hostname cases
    func test__002__ARTDomainSelector__primaryDomain__should_return_hostname_when_endpoint_contains_dot() {
        let selector = ARTDomainSelector(
            endpointClientOption: "test.ably.net",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "test.ably.net")
    }
    
    func test__003__ARTDomainSelector__primaryDomain__should_return_hostname_when_endpoint_contains_double_colon() {
        let selector = ARTDomainSelector(
            endpointClientOption: "::1",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "::1")
    }
    
    func test__004__ARTDomainSelector__primaryDomain__should_return_localhost_when_endpoint_is_localhost() {
        let selector = ARTDomainSelector(
            endpointClientOption: "localhost",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "localhost")
    }
    
    func test__005__ARTDomainSelector__primaryDomain__should_handle_IP_address() {
        let selector = ARTDomainSelector(
            endpointClientOption: "192.168.1.1",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "192.168.1.1")
    }
    
    // REC1b3: Non-production routing policy
    func test__006__ARTDomainSelector__primaryDomain__should_return_nonprod_domain_for_nonprod_routing_policy() {
        let selector = ARTDomainSelector(
            endpointClientOption: "nonprod:sandbox",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "sandbox.realtime.ably-nonprod.net")
    }
    
    // REC1b4: Production routing policy
    func test__008__ARTDomainSelector__primaryDomain__should_return_production_domain_for_routing_policy_id() {
        let selector = ARTDomainSelector(
            endpointClientOption: "test",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "test.realtime.ably.net")
    }
    
    // MARK: - REC2: Fallback Domains Tests
    
    // REC2a: Custom fallback hosts
    func test__010__ARTDomainSelector__fallbackDomains__should_return_custom_fallback_hosts_when_provided() {
        let customHosts = ["custom1.example.com", "custom2.example.com"]
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: customHosts,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, customHosts)
    }
    
    func test__011__ARTDomainSelector__fallbackDomains__should_override_defaults_with_custom_hosts() {
        let customHosts = ["fallback1.com", "fallback2.com"]
        let selector = ARTDomainSelector(
            endpointClientOption: "myrouting",
            fallbackHostsClientOption: customHosts,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, customHosts)
    }
    
    // REC2c1: Default fallback domains
    func test__012__ARTDomainSelector__fallbackDomains__should_return_default_fallback_domains() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        let expectedDomains = [
            "main.a.fallback.ably-realtime.com",
            "main.b.fallback.ably-realtime.com",
            "main.c.fallback.ably-realtime.com",
            "main.d.fallback.ably-realtime.com",
            "main.e.fallback.ably-realtime.com"
        ]
        
        XCTAssertEqual(selector.fallbackDomains, expectedDomains)
    }
    
    // REC2c2: Hostname has no fallbacks
    func test__013__ARTDomainSelector__fallbackDomains__should_return_empty_array_for_hostname() {
        let selector = ARTDomainSelector(
            endpointClientOption: "custom.ably.io",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains.count, 0)
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    func test__014__ARTDomainSelector__fallbackDomains__should_return_empty_array_for_localhost() {
        let selector = ARTDomainSelector(
            endpointClientOption: "localhost",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    func test__015__ARTDomainSelector__fallbackDomains__should_return_empty_array_for_IP_address() {
        let selector = ARTDomainSelector(
            endpointClientOption: "192.168.1.1",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    // REC2c3: Non-production routing policy fallbacks
    func test__016__ARTDomainSelector__fallbackDomains__should_return_nonprod_fallbacks_for_nonprod_routing_policy() {
        let selector = ARTDomainSelector(
            endpointClientOption: "nonprod:sandbox",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        let expectedDomains = [
            "sandbox.a.fallback.ably-realtime-nonprod.com",
            "sandbox.b.fallback.ably-realtime-nonprod.com",
            "sandbox.c.fallback.ably-realtime-nonprod.com",
            "sandbox.d.fallback.ably-realtime-nonprod.com",
            "sandbox.e.fallback.ably-realtime-nonprod.com"
        ]
        
        XCTAssertEqual(selector.fallbackDomains, expectedDomains)
    }
    
    // REC2c4: Production routing policy fallbacks
    func test__017__ARTDomainSelector__fallbackDomains__should_return_production_fallbacks_for_routing_policy() {
        let selector = ARTDomainSelector(
            endpointClientOption: "myrouting",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        let expectedDomains = [
            "myrouting.a.fallback.ably-realtime.com",
            "myrouting.b.fallback.ably-realtime.com",
            "myrouting.c.fallback.ably-realtime.com",
            "myrouting.d.fallback.ably-realtime.com",
            "myrouting.e.fallback.ably-realtime.com"
        ]
        
        XCTAssertEqual(selector.fallbackDomains, expectedDomains)
    }
    
    // MARK: - Legacy Options Tests
    
    // REC1c2: Deprecated environment option
    func test__018__ARTDomainSelector__primaryDomain__should_use_environment_option_when_set() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: "sandbox",
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "sandbox.realtime.ably.net")
    }
    
    // REC2c5
    func test__019__ARTDomainSelector__fallbackDomains__should_use_environment_for_fallbacks() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: "sandbox",
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        let expectedDomains = [
            "sandbox.a.fallback.ably-realtime.com",
            "sandbox.b.fallback.ably-realtime.com",
            "sandbox.c.fallback.ably-realtime.com",
            "sandbox.d.fallback.ably-realtime.com",
            "sandbox.e.fallback.ably-realtime.com"
        ]
        
        XCTAssertEqual(selector.fallbackDomains, expectedDomains)
    }
    
    // REC1d: Deprecated restHost option
    func test__020__ARTDomainSelector__primaryDomain__should_use_restHost_when_set() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: "custom-rest.ably.io",
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "custom-rest.ably.io")
    }
    
    // REC2c6
    func test__021__ARTDomainSelector__fallbackDomains__should_return_empty_for_restHost() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: "custom-rest.ably.io",
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    // REC1d: Deprecated realtimeHost option
    func test__022__ARTDomainSelector__primaryDomain__should_use_realtimeHost_when_set() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: "custom-realtime.ably.io",
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "custom-realtime.ably.io")
    }
    
    // REC2c6
    func test__023__ARTDomainSelector__fallbackDomains__should_return_empty_for_realtimeHost() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: "custom-realtime.ably.io",
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    // REC2b: Deprecated fallbackHostsUseDefault option
    func test__024__ARTDomainSelector__fallbackDomains__should_use_defaults_when_fallbackHostsUseDefault_is_true() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: true
        )
        
        let expectedDomains = [
            "main.a.fallback.ably-realtime.com",
            "main.b.fallback.ably-realtime.com",
            "main.c.fallback.ably-realtime.com",
            "main.d.fallback.ably-realtime.com",
            "main.e.fallback.ably-realtime.com"
        ]
        
        XCTAssertEqual(selector.fallbackDomains, expectedDomains)
    }
    
    // MARK: - Edge Cases
    
    func test__025__ARTDomainSelector__should_handle_empty_string_as_default() {
        let selector = ARTDomainSelector(
            endpointClientOption: "",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "main.realtime.ably.net")
    }
    
    func test__026__ARTDomainSelector__should_handle_empty_fallback_array() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: [],
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        // Empty array is provided, so it should use that instead of defaults
        XCTAssertEqual(selector.fallbackDomains, [])
    }
    
    func test__027__ARTDomainSelector__should_handle_complex_routing_policy_ids() {
        let selector = ARTDomainSelector(
            endpointClientOption: "my-complex-routing-123",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, "my-complex-routing-123.realtime.ably.net")
    }
    
    func test__028__ARTDomainSelector__should_handle_nonprod_with_empty_id() {
        let selector = ARTDomainSelector(
            endpointClientOption: "nonprod:",
            fallbackHostsClientOption: nil,
            environmentClientOption: nil,
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        XCTAssertEqual(selector.primaryDomain, ".realtime.ably-nonprod.net")
    }
    
    func test__029__ARTDomainSelector__should_prioritize_endpoint_over_environment() {
        let selector = ARTDomainSelector(
            endpointClientOption: "prod-routing",
            fallbackHostsClientOption: nil,
            environmentClientOption: "sandbox",
            restHostClientOption: nil,
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        // Endpoint should take priority
        XCTAssertEqual(selector.primaryDomain, "prod-routing.realtime.ably.net")
    }
    
    func test__030__ARTDomainSelector__should_prioritize_environment_over_restHost() {
        let selector = ARTDomainSelector(
            endpointClientOption: nil,
            fallbackHostsClientOption: nil,
            environmentClientOption: "sandbox",
            restHostClientOption: "custom-rest.ably.io",
            realtimeHostClientOption: nil,
            fallbackHostsUseDefault: false
        )
        
        // Environment should take priority over restHost
        XCTAssertEqual(selector.primaryDomain, "sandbox.realtime.ably.net")
    }
}


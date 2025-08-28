// Simple test to verify the endpoint implementation
#import <Foundation/Foundation.h>
#import "Source/include/Ably/ARTClientOptions.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        printf("Testing endpoint implementation...\n");
        
        // Test 1: Default endpoint behavior
        ARTClientOptions *defaultOptions = [[ARTClientOptions alloc] init];
        printf("Default endpoint: %s\n", [defaultOptions.effectiveEndpoint UTF8String]);
        printf("Default rest host: %s\n", [defaultOptions.restHost UTF8String]);
        printf("Default realtime host: %s\n", [defaultOptions.realtimeHost UTF8String]);
        
        // Test 2: Custom routing policy
        ARTClientOptions *customOptions = [[ARTClientOptions alloc] init];
        customOptions.endpoint = @"acme";
        printf("Custom endpoint: %s\n", [customOptions.endpoint UTF8String]);
        printf("Custom rest host: %s\n", [customOptions.restHost UTF8String]);
        printf("Custom realtime host: %s\n", [customOptions.realtimeHost UTF8String]);
        
        // Test 3: Nonprod routing policy
        ARTClientOptions *nonprodOptions = [[ARTClientOptions alloc] init];
        nonprodOptions.endpoint = @"nonprod:sandbox";
        printf("Nonprod endpoint: %s\n", [nonprodOptions.endpoint UTF8String]);
        printf("Nonprod rest host: %s\n", [nonprodOptions.restHost UTF8String]);
        printf("Nonprod realtime host: %s\n", [nonprodOptions.realtimeHost UTF8String]);
        
        // Test 4: FQDN endpoint
        ARTClientOptions *fqdnOptions = [[ARTClientOptions alloc] init];
        fqdnOptions.endpoint = @"custom.example.com";
        printf("FQDN endpoint: %s\n", [fqdnOptions.endpoint UTF8String]);
        printf("FQDN rest host: %s\n", [fqdnOptions.restHost UTF8String]);
        printf("FQDN realtime host: %s\n", [fqdnOptions.realtimeHost UTF8String]);
        
        // Test 5: Fallback hosts for different endpoints
        NSArray *mainFallbacks = [defaultOptions endpointFallbackHosts:@"main"];
        printf("Main fallback hosts count: %lu\n", (unsigned long)[mainFallbacks count]);
        
        NSArray *customFallbacks = [customOptions endpointFallbackHosts:@"acme"];
        printf("Custom fallback hosts count: %lu\n", (unsigned long)[customFallbacks count]);
        
        NSArray *nonprodFallbacks = [nonprodOptions endpointFallbackHosts:@"nonprod:sandbox"];
        printf("Nonprod fallback hosts count: %lu\n", (unsigned long)[nonprodFallbacks count]);
        
        NSArray *fqdnFallbacks = [fqdnOptions endpointFallbackHosts:@"custom.example.com"];
        printf("FQDN fallback hosts count: %lu\n", (unsigned long)[fqdnFallbacks count]);
        
        printf("All tests completed!\n");
    }
    return 0;
}

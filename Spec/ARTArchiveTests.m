@import XCTest;
#import <Ably/Ably.h>

@interface _StateMachineDelegate : NSObject <ARTPushRegistererDelegate>
@end

@implementation _StateMachineDelegate
- (void)didActivateAblyPush:(nullable ARTErrorInfo *)error { }
- (void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error { }
@end

@interface ARTArchiveTests : XCTestCase
@end

@implementation ARTArchiveTests
    
- (void)test_art_unarchivedObjectOfClass_for_state_machine_states {
    
    ARTRest* rest = [[ARTRest alloc] initWithKey:@"xxxx:xxxx"];
    ARTPushActivationStateMachine* stateMachine = [[ARTPushActivationStateMachine alloc] initWithRest:rest.internal delegate:[[_StateMachineDelegate alloc] init]];
    
    NSArray* initialStates = [NSMutableArray arrayWithArray:@[
        [[ARTPushActivationStateNotActivated alloc] initWithMachine:stateMachine],
        [[ARTPushActivationStateWaitingForPushDeviceDetails alloc] initWithMachine:stateMachine],
        [[ARTPushActivationStateAfterRegistrationSyncFailed alloc] initWithMachine:stateMachine]
    ]];
    
    NSData* data = [initialStates art_archive];
    
    NSArray* unarchivedStates = [NSObject art_unarchiveWithAllowedClass:[ARTPushActivationState class] fromData:data];
    
    XCTAssert([unarchivedStates[0] isKindOfClass:[ARTPushActivationStateNotActivated class]]);
    XCTAssert([unarchivedStates[1] isKindOfClass:[ARTPushActivationStateWaitingForPushDeviceDetails class]]);
    XCTAssert([unarchivedStates[2] isKindOfClass:[ARTPushActivationStateAfterRegistrationSyncFailed class]]);
}

@end

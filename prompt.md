Look at the plan described in @ably-cocoa-swift-migration-prd.md. The migration of ARTRealtimePresence.m has been started but not completed. In particular, ARTRealtimePresenceInternal needs implementing. Your task is to implement ARTRealtimePresenceInternal.

Things you MUST pay particular attention to:

- make sure that atomic properties are migrated per the rules of the PRD (i.e. use locks)
- use Dictionary instead of NSDictionary and NSMutableDictionary
- note that for Swift I have changed the signature of `history()` to throwing; when migrating the code be sure to meet this new API
- do NOT try and implement the initializer of ARTRealtimePresenceInternal; this will be complicated and we'll do that separately
- first of all, look at the usage of the ARTPresenceActionAll value; this appears to be a hack that won't work in Swift because you can't force this value into the ARTPresenceAction enum; perhaps we'll have to have a second enum internally which is either an ARTPresenceAction or `.all`. suggest what we could do before you start writing code

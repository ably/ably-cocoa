Look at the plan described in @ably-cocoa-swift-migration-prd.md. The migration f ARTRealtimePresence.m has been started but not completed. In particular, ARTRealtimePresenceInternal needs finishing. Its properties and initializer have already been implemented. Your task is to implement ARTRealtimePresenceInternal.

Things you MUST pay particular attention to, along with all the rules of the PRD:
j
- use Dictionary instead of NSDictionary and NSMutableDictionary
- note that for Swift I have changed the signature of `history()` to throwing; when migrating the code be sure to meet this new API
- look at the usage of the ARTPresenceActionAll value; this appears to be a hack that won't work in Swift because you can't force this value into the ARTPresenceAction enum. I suggest that we keep using ARTPresenceAction publicly but internally have a PresenceActionFilter enum which is either an `ARTPresenceAction` or .`all`


Look at the migration plan in @ably-cocoa-swift-migration-prd.md. We need to implement
  ARTRealtimePresenceInternal. We'll have to do this in stages. Begin by just implementing the
  properties (internal and external) of this class, paying VERY CAREFUL attention to make sure
  that atomic properties are migrated following the rules of the PRD. make sure to implement any
  custom getters as needed. Don't try and build the code now

Look at the migration plan in @ably-cocoa-swift-migration-prd.md. We need to implement ARTRealtimeInternal. We'll have to do this in stages. Begin by just implementing the properties (internal and external) of this class. MAKE SURE to implement any custom getters that exist in the original code. Don't try and implement the initializer. Don't try and build the code now. Don't delete any of the existing code in this file. Remember that we want to use Swift types instead of Foundation types (e.g. Array instead of NSMutableArray) per the PRD.

Your task is to review the proposal for Jira issue AIT-1023; that is, the new LiveObjects Swift public API that is being proposed in https://github.com/ably/ably-cocoa/pull/2218. (You are being invoked from a checkout of this branch.)

## Context

This PR proposes how the "path-based API" should be represented in Swift. The path-based API is a new API which simplifies the usage of the library. This API has already shipped in ably-js and can be found on `main` of that repo.

Although ably-js is the only shipping version of this API, we have, since shipping it, thought about how we would like to adapt this API for Swift and Kotlin ("strongly typed languages" I believe our subsequent thinking documents have referred to them as). We have a few disparate sources describing the design of how we believe these languages should represent this API, of increasing levels of authority but differing in their level of language-specificity.

## The targeted repo

This PR currently targets the ably-cocoa repo for reasons that aren't completely clear to me. However, what this PR _represents_ is a modification to the public API contained in the ably-liveobjects-swift-plugin repo. You should review the PR through this lens; that is, you should work out what this PR changes when compared to the state of that plugin repo at `main`. For example, the `JSONValue` type added in this PR already exists in the plugin repo; thus when reviewing this type you should compare the type from the two repos and find out what (if anything) has changed, as opposed to re-reviewing the entire type.

## Existing design sources

The current ably-liveobjects-swift-plugin repo is based on a pre-path-based version of the ably-js API. There are design decisions there that are intentional deviations from ably-js (for example, the way in which users unsubscribe from within a subscription listener). These decisions may or may not be relevant in the post-path-based-API world.

These are the sources that describe the path-based API and our thoughts on how to port it:

- `ably-js` on `main`
- https://github.com/ably/ably-liveobjects-swift-plugin/pull/128 — This was my proposal for how we would port the path-based API to Swift. It represents the first thinking that we as a team did on this topic. Some of it is out of date, in that it was created based on a version of the ably-js API that may have subsequently changed (as mentioned in `PATH-BASED-API-MAIN-DELTA.md` there), and it proposed APIs (e.g. `.asLiveMap` etc) that we have subsequently refined in later design documents. I believe that it is also incomplete and did not try to port every corner of the API surface, focussing on the big decisions. It is worth looking at it, still (in particular the `PATH-BASED-API.md` notes and the code), to see whether there are any Swift-specific ideas that I had there that we would like to be reflected in the final API. The `PATH-BASED-API-JAVA-PYTHON-COMPARISON.md` there is based on an older proposal for the Java/Python APIs and can be ignored.
- https://github.com/ably/specification/pull/485 — This is the specification for the path-based API as built in ably-js. I (Lawrence) worked on this PR and am familiar with its contents. The changes of this PR are largely additive but also there are a few changes to existing public APIs.
- https://ably.atlassian.net/wiki/spaces/AI/pages/5127372801/Final+Assessment+of+the+LiveObjects+Path-Based+API+for+Java+and+Swift — This is a proposal for how the path-based API should work in strongly typed languages. I have looked at some version of this page in the past and been involved in discussions around its contents.
- https://github.com/ably/specification/pull/489 — This is a simple renaming of types, built on top of #485.
- https://github.com/ably/specification/pull/491 — This is a specification for how strongly-typed languages should implement the path-based API. As I understand it, this page intends to specify the decisions that were described in the "Final Assessment of the LiveObjects Path-Based API for Java and Swift" Confluence page linked above. I have not looked at this page in detail, however it should be taken as the source of truth unless you believe it to contain errors that do not reflect the decisions taken in the Confluence page. In particular, the IDL changes introduced there should be taken as the decided generic shape of the public API for strongly-typed languages. Note that, as with all parts of the Ably specification, it describes a language-agnostic interface that broadly describes the intended API shape and semantics but leaves ergonomic decisions to individual implementations.
- Branch `feature/path-based-liveobjects-implementation` of ably-java — As I understand it, this branch contains ably-java's final decision on the shape of the path-based API; that is, I believe that it represents ably-java's decision on how to implement spec PR #491. I have not looked at it but it may be a useful source when seeing how an other strongly-typed language has chosen to interpret the spec.
- The comments that have already been left on ably-cocoa#2218 (the PR under review) — in particular those by Sachin, the author of the Confluence page and spec PR #491.
- My [comment](https://ably.atlassian.net/browse/AIT-1023?focusedCommentId=99493) on AIT-1023 in which I explained the design decision that we chose to take for `Instance` in Swift (if you cannot fetch this comment or cannot see the code snippet then you must not proceed; ask me and I'll give you the contents) — take this comment as authoritative

Feel free to check out any of these branches locally if you need to look at their contents in detail.

**Update**: I found out that you are unable to access the aforementioned comment on AIT-1023; here it is (it reads like a question but take it as decided "yes"):

> @Sachin Shinde @Evgenii Khokhlov please can you re-confirm my understanding from the conversation the other day? i.e. that in ably-java `PathObject.instance()` will return a sub-type of `Instance` which is decided based on the type of the underlying object at that path, i.e. users can find out what type of object lies at a given path purely by checking the type of what `PathObject.instance()` returns? e.g. if there’s a LiveCounter at that path then it’ll return a `LiveCounterInstance`
> 
> And if so, we then agreed that the equivalent in Swift would be (to allow for exhaustive checking on the different instance types) for `PathObject.instance()` to return an enum, so roughly something like:
> 
> ```swift
> protocol PathObject {
>   …
>   func instance() throws -> Instance
> }
> 
> enum Instance {
>   case liveMap(LiveMapInstance)
>   case liveCounter(LiveCounterInstance)
>   case primitive(PrimitiveInstance)
> }
> ```
>
> etc
> 
> Is that right?
> 
> cc @Marat Alekperov

## Initial thoughts on the PR

I have not looked at the PR in detail (I am delegating this to you) but a few things that stand out from the PR description as of 2026-07-03T09:55+01:00 are:

- It does not seem to have consulted the full list of sources that I listed above
- It is not clear about where the IDL excerpt that it uses was taken from
- It does not explain any Swift-specific decisions that it made in porting the path-based API, so it is hard to reason about which parts of the proposed API are uncontroversial ports, which are ad-hoc divergences, and which are divergences that follow some decided but uncommunicated pattern (and in the latter case whether this pattern is one that already existed in the current version of the Swift plugin).

## What to review

- Whether this PR accurately represents the decisions made in the linked sources
	- When there are tensions between different sources explain which has been used
- Whether the API has been ported comprehensively
- Whether it re-litigates general decisions that had already been made in the Swift LiveObjects plugin, including but not limited to:
	- whether to use properties instead of methods
	- how subscriptions work
	- usage of Swift value types
- Whether there are things that could be done to make it a more Swift-native API
- Whether methods are correctly annotated with `throws` (the specification points that describe the behaviour of these methods are the best source of truth for this) and `async`
- Whether types are correctly annotated with `Sendable`
- Whether return types of the JSON-returning objects have been correctly mapped to Swift
- The inheritance hierarchy that has been chosen for `PathObject` / `Instance` and how it relates / diverges from the decisions made in the spec and in ably-java
	- How this relates to narrowed return types and the limitations surrounding this in Swift; for example how has `compactJson()`'s narrowing for `LiveMapInstance` been ported to Swift?
- Whether the spec point references on the methods are correct

You should also:

- Infer what seem to be general patterns made in deciding how to port this API and present them to me, for easier review

## Requirements for your output

Additional requirements for how you should structure your output:

- You must list all the sources that you consulted. For each source, you must mention the version of that source that you consulted:
	- For Git repos, mention the branch name (and the PR name if you know it) and the commit at which you viewed that branch.
	- For Confluence pages, mention the timestamp at which you fetched the page; if your tools give you access to the page version number then mention that too.
	- For PR descriptions, mention the timestamp at which you fetched them; if your tools give you access to some sort of version identifier for the PR version then mention that too.
	- For "I looked at all the comments on a PR" mention the date as of which you'd seen all the comments on the PR.

The output should be a document that is concise and self-contained. It should be suitable for sharing with the author of the PR (i.e. it should not directly address Lawrence).
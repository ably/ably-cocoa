Some further changes to make:

- Create a copy of this table in a new file swift-migration-overall-progress.md (with an extra column to indicate the progress of the migration of each row) and update the implementation plan to state that this file must be updated during implementation to show the progress
- Also state that we must track the progress of the migration of each set of files in a new file swift-migration-files-progress.md, with a subheading for each set of files.
- Update the proposed locations of the created .swift files; they should all just go into a single directory, don't try and categorise them.

Now, some other things to incorporate:

## Rules to incorporate about errors and warnings

To test that the changes work, `swift build` must be run before deciding that the migration of a set of files is complete. Handle errors and warnings as follows:

- To handle compilation errors:
	- If an error can be fixed in a very obvious way, then do so and make a note of it against that file in swift-migration-files-progress.md
	- If fixing an error would require a significant deviation from the Objective-C code, then leave the code as-is, stop what you're doing, and ask the user how to proceed.
- To handle compilation warnings:
	- If a warning can be fixed in a very obvious way, then do so and make a note of it in swift-migration-files-progress.md
	- If fixing a warning would require a significant deviation from the Objective-C code, then leave the code as-is and just make a note of this decision in swift-migration-files-progress.md

- Handling of specific warnings:
	- Ignore warnings that relate to the result of a method call being unused 
	- Ignore warnings that relate to the compiler's concurrency safety checking, e.g. `Capture of 'callback' with non-sendable type 'ARTCallback?' (aka 'Optional<(Optional<ARTErrorInfo>) -> ()>') in a '@Sendable' closure`

## Placeholder management

Since files have dependencies, we might migrate a file before some of its dependencies have been migrated, causing the build to fail. To mitigate this, when we encounter a type that has not yet been migrated, we will create a placeholder type for it.

- All placeholder types should go into a single separate file called `MigrationPlaceholders.swift`, and should be removed from there once the proper type is implemented. IMPORTANT: Do not put placeholder types in any other Swift files.
- To create placeholder types in `MigrationPlaceholders.swift`, first of all look up the full type (for a `class` this may involve looking in multiple header files), and then:
	- For an `enum`, create the full enum.
	- For a `protocol`, create the full protocol so that other classes can call methods on it.
	- For a `class`, create the class, but with a dummy `fatalError()`-calling implementation for all of its methods and property getters and setters. This will allow other classes to call methods on it.
	- For an extension, create the extension, but with a dummy `fatalError()`-calling implementation for all of its methods and property getters and setters. This will allow other classes to call methods on it.

## Commenting the migrated code

In order to allow a human reviewer to distinguish any original comments from those created by the migration, ALL code comments that describe a decision taken during the migration MUST begin with ``swift-migration: ``.

The migration MUST do its best not to modify or skip any code (in a manner that's consistent with the rules for warnings and errors). If it does modify or skip code in a file, it MUST leave a `swift-migration: ` code comment, and leave a note about this under this file's entry in swift-migration-files-progress.md.

### `NSMutableArray` queueing extension methods

Do not migrate the following methods; instead just use the following at the call sites in `ARTRealtime`.

- `NSMutableArray.art_enqueue` — use `Array.append`
- `NSMutableArray.art_dequeue` — use `Array.popFirst`
- `NSMutableArray.art_peek` — use `Array.first`

### Methods that accept `NSMutableDictionary`

There are two places in the codebase where we have a method that accepts an `NSMutableDictionary`:

- `ARTMessageOperation.writeToDictionary:`
- `ARTJsonLikeEncoder.writeData:…`

In both cases, implement these in Swift by accepting an `inout Dictionary`.

## Platform conditionals

A platform conditional like `#if TARGET_OS_IOS` should be migrated to `#if os(iOS)`.

Claude's currently working on incorporating the above. Some further stuff:

- the headers in the table should show the base header first, then the extension headers
- `swift-migration-files-progress.md` should show the names of the geaders too, in the same order
- get rid of stuff that has to do with changing the build configuration; that's already been taken care of
- make it clear that the stuff under "Swift Migration Challenges to Resolve" are _requirements_ that must be met by the migration

Now it's working on those.

(I note that it's really slow to do some stuff that doesn't seem like it should take so long, I don't know if that's because it's like generating a program or something to do it). I also don't like the fact that when I asked it to incorporate my notes, it did it in a style that I didn't like compared to the original language I gave it, dropping some little bits of the insturctions.

Another one:

- before each migrated entity, add a `swift-migration:` comment explaining the file and line that this entity came from, e.g. `// swift-migration: original location Foo.m, line 123`

> > Read the plan in ably-cocoa-swift-migration-prd.md. Does this plan make it sufficiently clear
>   to an LLM tasked with executing this plan that the aim is to modify the Objective-C code as
>   little as possible (with the exception of the permitted deviations), and that when deviations
>   are made they should be exposed to a human reviewer in a variety of very specific manners?
> 
> ⏺ I'll read the plan document to understand the migration strategy and assess whether it
>   clearly communicates the objective to minimize Objective-C modifications and the requirements
>    for exposing deviations to reviewers.
> 
> ⏺ Read(ably-cocoa-swift-migration-prd.md)
>   ⎿  Read 557 lines (ctrl+r to expand)
> 
> ⏺ Based on my review of the plan document, I can assess whether it makes the objectives
>   sufficiently clear to an LLM:
> 
>   The plan is VERY clear about minimizing Objective-C modifications:
> 
>   1. Explicitly states the "carbon-copy" approach - Section "Migration Strategy" emphasizes
>   "Mechanical Carbon-Copy Translation" with rationale focused on preserving existing logic
>   2. Multiple reinforcements - The plan repeatedly states goals like "preserve existing
>   battle-tested logic," "direct syntax translation vs architectural redesign," and "clear 1:1
>   mapping between old and new code"
>   3. Specific technical requirements preserve all API compatibility without requiring
>   Objective-C interoperability
> 
>   However, the plan has some weaknesses regarding deviation tracking:
> 
>   GOOD - Clear deviation documentation requirements:
>   - All migration comments must start with swift-migration:  prefix
>   - Required source location comments before each entity
>   - Documentation in both code and progress files
>   - Specific rules for error/warning handling
> 
>   GAPS - Could be more specific about deviation exposure:
>   - Doesn't explicitly define what constitutes a "significant deviation"
>   - Lacks specific examples of when to "stop migration and ask user for guidance"
>   - Could be clearer about what level of review human reviewers should expect
>   - The "obvious fixes" vs "significant deviations" distinction could use more concrete
>   criteria
> 
>   Recommendation: The plan would benefit from a more detailed section defining deviation
>   thresholds and examples of when LLM should halt for human input, but overall it does
>   communicate the minimal-change objective clearly.

I don't yet know what I mean by a "sigificant deviation", so I think perhaps let's try a few files and find out.

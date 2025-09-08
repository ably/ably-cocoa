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
- `swift-migration-files-progress.md` should show the names of the headers too, in the same order
- get rid of stuff that has to do with changing the build configuration; that's already been taken care of
- make it clear that the stuff under "Swift Migration Challenges to Resolve" are _requirements_ that must be met by the migration

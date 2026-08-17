# macOS PDF Import Permission Validation

**Date**: 2026-07-19
**Spec**: `.specs/features/library_import/spec.md` (there is no feature-local spec)
**Diff range**: `835e137^..835e137`
**Verifier**: independent sub-agent (author != verifier)

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| Add the user-selected read-only entitlement to Debug/Profile and Release | ✅ Done | Exact entitlement is enabled in both committed plist files. |
| Add a regression test for both entitlement configurations | ✅ Done | Two configuration-specific tests were added. |

The commit is surgical: two entitlement entries and one 21-line architecture
test. No production Dart behavior, picker behavior, persistence, or error handling
was changed.

## Spec-Anchored Acceptance Criteria

The entitlement is a macOS platform prerequisite for reading the external file
returned by the user-selected file picker. The source specification describes the
observable import outcomes, but does not prescribe the Apple entitlement name.
Accordingly, evidence below distinguishes the new declarative permission check
from the already-existing behavioral tests.

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| P1 Import AC1: activating import opens a PDF-restricted picker | One file, custom PDF filter | `test/features/import_book/data/services/file_picker_pdf_picker_test.dart:27` — `expect(capturedAllowMultiple, isFalse)`; lines 28-29 assert `FileType.custom` and `['pdf']` | ✅ PASS |
| P1 Import AC3: a missing, directory, unreadable, or non-PDF path changes nothing and shows the standard error | Typed validation rejection and standard import error | `test/features/import_book/data/services/local_book_file_storage_test.dart:107` — `expectLater(... throwsA(...kind...))`; `test/features/import_book/domain/services/import_book_service_test.dart:105` — exact `ImportBookException.message`, then lines 116-120 assert no partial active copy, old file retained when applicable, and no inserted record | ✅ PASS |
| P1 Import AC4: a valid PDF is hashed and copied to a unique private path off the UI isolate | Exact digest, private staged copy, and worker isolate identity different from caller | `test/features/import_book/data/services/local_book_file_storage_test.dart:55` — exact SHA-256; line 59 asserts copied payload; lines 60-63 assert both operations ran outside the caller isolate; `test/features/import_book/domain/services/import_book_service_test.dart:29` — exact durable `Book`, including `/books/book-1.pdf` and hash | ✅ PASS |
| P1 Import AC6: copy or persistence failure removes partial copy, preserves prior state, and returns the exact error | Exact Portuguese error, no partial active copy, no new row, prior duplicate retained | `test/features/import_book/domain/services/import_book_service_test.dart:105` — exact thrown message; lines 116-120 assert compensation for every enumerated failure point | ✅ PASS |
| Applicable success criterion: one valid import produces one durable visible item and one private PDF | Visible title, private PDF, and durable record after the import flow | `test/widget_test.dart:148` activates import; lines 160-165 assert one visible title, the private PDF, and the persisted record/status | ✅ PASS |
| macOS permission correction | Both Xcode entitlement configurations used by the app contain `com.apple.security.files.user-selected.read-only = true` | `test/architecture/macos_pdf_import_entitlements_test.dart:12` — `expect(entitlements, contains('<key>...read-only</key>\\n\\t<true/>'))`; production values at `macos/Runner/DebugProfile.entitlements:7` and `macos/Runner/Release.entitlements:7`; Xcode selects these files at `macos/Runner.xcodeproj/project.pbxproj:584`, `:716`, and `:736` | ✅ PASS |

**Status**: ✅ The scoped permission correction matches the spec-required
outcome and existing behavioral coverage. No spec-precision gap blocks this
commit: the spec intentionally states behavior rather than a platform-specific
entitlement.

## Edge Cases and Applicable Success Criteria

- [x] Uppercase `.PDF`, empty readable PDFs, invalid file kinds, disappearance,
  copy failure, disk-full failure, repository failure, and duplicate rollback are
  exercised by the existing import tests.
- [x] The new permission is present in Debug/Profile and Release, the two
  entitlement files selected by the macOS Xcode configurations.
- [x] Both plist files are structurally valid (`plutil -lint`: `OK`).
- [ ] A signed, sandboxed macOS application was not driven through a native file
  picker during this automated pass. The architecture test proves configuration,
  not OS-level runtime enforcement. This is a residual UAT limitation, not a
  contradiction in the committed correction.

## Gate Check

- **Targeted command**: `flutter test test/architecture/macos_pdf_import_entitlements_test.dart`
- **Targeted result**: 2 passed, 0 failed, 0 skipped
- **Structural command**: `plutil -lint macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements`
- **Structural result**: both files `OK`
- **Repository gate**: `flutter analyze && flutter test`
- **Repository result**: analysis found no issues; 372 tests passed, 0 failed,
  0 skipped
- **Test count before/after commit**: 370 / 372 inferred from the commit adding
  exactly two loop-generated test cases; delta +2
- **Build-runner/APK portions of the library feature build gate**: not rerun.
  They are not discriminating for a macOS entitlement-only correction; analysis,
  the complete test suite, plist validation, and Xcode entitlement wiring are the
  relevant scoped gates.
- **Warnings**: Flutter reported that `flutter_tts` does not support Swift Package
  Manager for iOS/macOS. This warning is pre-existing and unrelated to the diff.

## Discrimination Sensor

Mutations were performed only in `/tmp/vox-macos-entitlements.M9dLJU`; the real
implementation and tests were not mutated.

| Mutation | File | Description | Result |
| -------- | ---- | ----------- | ------ |
| 1 | `macos/Runner/DebugProfile.entitlements` | Removed the user-selected read-only key/value pair | ✅ Killed: DebugProfile test failed |
| 2 | `macos/Runner/Release.entitlements` | Changed the entitlement value from `true` to `false` | ✅ Killed: Release test failed |

**Sensor depth**: lightweight, two targeted behavior/configuration mutations  
**Result**: 2/2 killed — PASS ✅

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code; no unrequested feature | ✅ |
| Surgical changes only | ✅ |
| No unnecessary abstraction or flexibility | ✅ |
| Matches existing plist and Flutter-test style | ✅ |
| Existing assertions were not weakened or deleted | ✅ |
| Tests map to the platform prerequisite for P1 import | ✅ |
| Spec-anchored asserted values match the expected outcome | ✅ |
| No unclaimed test: both generated cases claim Debug/Profile or Release permission | ✅ |
| Guidelines followed: `analysis_options.yaml`, `.github/workflows/ci.yml`, `.specs/features/library_import/tasks.md`, plus strong defaults | ✅ |

The test is deliberately small and discriminating. Its string assertion is
format-sensitive, but that does not weaken the guarantee: it rejects a missing
key and a false value. A structured plist parser would be more flexible but would
be unnecessary for this fixed-format project contract.

## Summary

**Overall**: ✅ PASS — ready for the scoped macOS permission correction

**Spec-anchored check**: 4/4 requested P1 ACs and 1/1 applicable success
criterion have exact behavioral evidence; the macOS prerequisite has exact
configuration evidence.

**Sensor**: 2/2 mutations killed  
**Gate**: 372 tests passed; analysis clean; both plists valid

**Residual gap**: no native, signed, sandboxed macOS picker/import UAT was run.
If release confidence requires proof beyond configuration, perform one manual
Release-build import from a user-selected file outside the app container and
verify the visible durable item and private copy.


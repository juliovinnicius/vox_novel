# Android PDF Worker Cache Validation

**Date**: 2026-07-19
**Spec**: `.specs/features/text_processing/spec.md` — P1 “Extract and retain PDF text” (`TXT-01`)
**Diff range**: `71a07e0^..68e5930`
**Verifier**: independent sub-agent (author ≠ verifier)
**Verdict**: ✅ PASS

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| Forward the Flutter cache path into the PDF worker | ✅ Done | `lib/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart:42-48` |
| Initialize pdfrx in the worker with that path | ✅ Done | `lib/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart:123-132` |
| Prove the Android-specific regression is detected automatically | ✅ Done | Fix commit `68e5930`; both required mutants are killed. |

## Spec-Anchored Acceptance Criteria

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| TXT-01 AC3: selectable PDF extraction | Exact text in ascending one-based page order, retaining empty page text | `test/features/pdf_processing/data/services/pdfrx_pdf_text_extractor_test.dart:33-49` — exact event count, page numbers, page counts, texts, and completion | ✅ PASS on host |
| TXT-01 AC6: corrupt/protected extraction failure | No partial text; standard failed processing outcome | `test/features/pdf_processing/data/services/pdfrx_pdf_text_extractor_test.dart:62-99` — exact sanitized failure kind and no page events | ✅ PASS at extractor boundary |
| Android worker has no usable `HOME` and must use the Flutter cache path | Selectable private PDF completes rather than failing during pdfrx initialization | `test/architecture/android_pdf_worker_initialization_test.dart:12-13` — asserts both `Pdfrx.cacheDirectoryPath,` in the isolate arguments and `pdfrxInitialize(tmpPath: cacheDirectoryPath)` in the worker | ✅ PASS |

**Runtime evidence supplied by author**: on Android device `2210129SG`, before the change `_getPdfrxCacheDirectory` failed at line 63 because `HOME` was null and processing returned `ProcessingOutcome.failed`; after forwarding `cacheDirectoryPath` and calling `pdfrxInitialize(tmpPath: cacheDirectoryPath)`, the same private PDF returned `ProcessingOutcome.completed`. This supports the implementation outcome but is not independently reproducible evidence and does not close the automated discrimination gap.

## Build-Level Gate

Command: `flutter analyze && flutter test test/architecture/android_pdf_worker_initialization_test.dart test/features/pdf_processing/data/services/pdfrx_pdf_text_extractor_test.dart && flutter build apk --debug`

- Analyze: ✅ no issues
- Scoped tests: ✅ 9 passed, 0 failed, 0 skipped
- Android debug APK: ✅ built at `build/app/outputs/flutter-apk/app-debug.apk`
- Test-count regression: no test deleted; fix commit adds one assertion

## Discrimination Sensor

Scratch state only; the real implementation and tests were not mutated.

| Mutation | Description | Result |
| -------- | ----------- | ------ |
| M1 | Replaced `pdfrxInitialize(tmpPath: cacheDirectoryPath)` with `pdfrxInitialize()` | ✅ Killed by `android_pdf_worker_initialization_test.dart:13` |
| M2 | Replaced the cache path sent in the isolate argument tuple with `null`, while retaining `pdfrxInitialize(tmpPath: cacheDirectoryPath)` | ✅ Killed by `android_pdf_worker_initialization_test.dart:12` |

**Sensor depth**: lightweight, two behavior-level mutations  
**Result**: 2/2 killed — ✅ PASS

## Edge Cases

- Corrupt PDF: ✅ exact sanitized corrupt failure and no page payload.
- Password-protected PDF: ✅ exact sanitized protected failure and no page payload.
- Empty page among selectable pages: ✅ retained with empty text and ordered page number.
- Android isolate with null `HOME`: ✅ author runtime evidence demonstrates completion, and both cache-propagation regression mutants are now detected.

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum/surgical production change | ✅ |
| No unrelated scope in commit | ✅ |
| Matches existing isolate argument pattern | ✅ |
| Spec-anchored functional assertions | ✅ |
| Regression test discriminates both required wiring faults | ✅ |
| Every scoped test maps to TXT-01 or the Android regression | ✅ |
| Documented guidelines | `.specs/features/text_processing/tasks.md`; strong defaults otherwise |

## Final Status

✅ **PASS** — production behavior is supported by the supplied device evidence, the relevant gate is green, and both exact regression mutants are killed.

No new lesson was recorded because the re-verification is clean.

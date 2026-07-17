# Library and Import Validation — Iteration 2

**Date**: 2026-07-17
**Spec**: `.specs/features/library_import/spec.md`
**Diff range**: `e40c552..bd6e6cc`
**Verifier**: independent sub-agent (author ≠ verifier)
**Verdict**: PASS

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1–T14 | ✅ Done | Original implementation tasks remain complete. |
| F1 | ✅ Done | Cleanup failure now compensates the database row and quarantined files, including restart evidence. |
| F2 | ✅ Done | Production validation/hash and stage-copy use `Isolate.run`; caller/worker identities are asserted. |
| F3 | ✅ Done | Status, dialog initialization/cancellation, restart/order/default-layout, and latency evidence added. |
| F4 | ✅ Done | Mid-copy, disk-full, empty-cover, and exact mutation-emission payloads added. |

## Spec-Anchored Acceptance Criteria

### LIB-01 — Import a PDF into private storage

| # | Spec-defined outcome | Exact evidence (`file:line` + assertion) | Result |
| - | -------------------- | ---------------------------------------- | ------ |
| 1 | Picker permits one custom-extension selection with exactly `pdf`. | `test/features/import_book/data/services/file_picker_pdf_picker_test.dart:27` — `expect(capturedAllowMultiple, isFalse)`; `:28` — `expect(capturedType, FileType.custom)`; `:29` — `expect(capturedAllowedExtensions, ['pdf'])`. | ✅ |
| 2 | Cancellation emits selecting then idle with no error/library mutation. | `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:39` — `emitsInOrder([selecting, ImportBookState()])`; `test/widget_test.dart:139` — repository result remains the exact pre-dialog `book`. | ✅ |
| 3 | Invalid selection leaves storage/repository unchanged and exposes `Não foi possível importar este PDF`. | `test/features/import_book/data/services/local_book_file_storage_test.dart:107` — exact typed validation-kind matcher; `test/features/import_book/domain/services/import_book_service_test.dart:105` — exact error string plus `:116` `partialActive == false` and `:120` `inserted == null`; `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:56` — exact UI-state error. | ✅ |
| 4 | Valid PDF gets exact SHA-256 and a private unique copy off the caller/UI isolate. | `test/features/import_book/data/services/local_book_file_storage_test.dart:55` — exact digest; `:59` — copied bytes equal `isolate payload`; `:60` — two worker callbacks; `:62` — every worker identity differs from caller. | ✅ |
| 5 | Exactly one initial book has stable ID, derived title, null author/cover, exact file fields, `importing`, zero progress, and equal timestamps. | `test/features/import_book/domain/services/import_book_service_test.dart:29` — whole-`Book` equality with all values at `:31-43`; `:45` — inserted object is the result; `:46` — exact validate/stage/commit sequence. | ✅ |
| 6 | Every copy/persistence failure removes partial state, retains prior state, and reports the standard error. | `test/features/import_book/domain/services/import_book_service_test.dart:87` iterates every failure point; `:105-113` asserts exact exception text; `:116-120` assert no partial/new insert and old file retained for replacement. | ✅ |
| 7 | Active import is indeterminate, disabled, and state/frame responsive. | `test/features/library/presentation/pages/library_page_test.dart:56` — one `LinearProgressIndicator`; `:60` — FAB callback null; `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:79-82` — pending import state remains synchronously readable and second call is ignored. | ✅ |

### LIB-02 — Replace duplicate content safely

| # | Spec-defined outcome | Exact evidence (`file:line` + assertion) | Result |
| - | -------------------- | ---------------------------------------- | ------ |
| 1 | A new hash inserts exactly one new book. | `test/features/import_book/domain/services/import_book_service_test.dart:29-46` — exact new-book value, one inserted result, and no replacement event. | ✅ |
| 2 | Duplicate preserves ID/title/author/cover/createdAt and replaces only approved import fields. | `test/features/import_book/domain/services/import_book_service_test.dart:64` — whole result equals `existing.copyWith(...)` with exact replacement values at `:66-73`; `:75` — stable ID `book-7`. | ✅ |
| 3 | Old PDF cleanup occurs only after new file and row are durable. | `test/features/import_book/domain/services/import_book_service_test.dart:76` — exact `validate, stage, backup, commit, discardBackup` order; `:83` — `replacementCompletedBeforeCleanup == true`. | ✅ |
| 4 | Failed replacement keeps/restores old record/file and removes partial replacement. | `test/features/import_book/domain/services/import_book_service_test.dart:87-120` — failure matrix asserts exact standard failure, no partial, old file available, and no new insert. | ✅ |
| 5 | Concurrent requests execute only the first. | `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:61-70` and `:73-84` — selection/import pending cases both assert `picker.calls == 1` and unchanged active state. | ✅ |

### LIB-03 — Browse the local library

| # | Spec-defined outcome | Exact evidence (`file:line` + assertion) | Result |
| - | -------------------- | ---------------------------------------- | ------ |
| 1 | Empty state shows `Sua biblioteca está vazia` and accessible `Importar PDF`. | `test/features/library/presentation/pages/library_page_test.dart:23-25` — exact title, empty copy, and action text. | ✅ |
| 2 | Each book renders once with title, optional author, and the exact label for all five statuses. | `test/features/library/presentation/widgets/book_item_test.dart:32-34` — exact title/author/importing label and one widget; `:50` — empty author absent; `:53-75` — exact `Importando`, `Processando`, `Pronto`, `Falhou`, `Não suportado` mapping. | ✅ |
| 3 | Grid preserves the same ordered books/data and uses exactly two phone columns. | `test/features/library/presentation/pages/library_page_test.dart:35-44` — each keyed ID occurs once before/after and `crossAxisCount == 2`; `test/features/library/presentation/cubit/library_cubit_test.dart:34-36` — exact books preserved. | ✅ |
| 4 | List preserves the same one-column ordered books/data. | `test/features/library/presentation/cubit/library_cubit_test.dart:37-40` — layout is list, exact book list unchanged, fresh Cubit defaults list. | ✅ |
| 5 | Restart loads durable data newest-first and defaults to list. | `test/widget_test.dart:259-299` — seeds a file-backed Drift database, closes it, starts two fresh applications; `:302` — exact list layout; `:303-306` — IDs exactly `newer, older`; `:307-310` — visible vertical order matches. | ✅ |
| 6 | First query and visible result completes in less than two seconds. | `test/widget_test.dart:297-301` — stopwatch spans fresh app/query/render and asserts `< Duration(seconds: 2)`; visible titles are located at `:308-309`. | ✅ |

### LIB-04 — Edit book metadata

| # | Spec-defined outcome | Exact evidence (`file:line` + assertion) | Result |
| - | -------------------- | ---------------------------------------- | ------ |
| 1 | Form inputs contain current title and author. | `test/features/library/presentation/widgets/book_dialogs_test.dart:23-25` — controller texts exactly `Title` and `Author`. | ✅ |
| 2 | Valid save persists trimmed title/author, exact update time, and renders the title. | `test/features/library/domain/services/library_service_test.dart:25-26` — success and exact tuple `('Novo título', 'Autora nova', now)`; `test/widget_test.dart:164-171` — trims `Renomeado` and renders it. | ✅ |
| 3 | Blank trimmed title shows `Informe o título` and performs no mutation. | `test/features/library/domain/services/library_service_test.dart:43-45` — failure, exact message, metadata call null; `test/features/library/presentation/widgets/book_dialogs_test.dart:26-29` — exact visible validation. | ✅ |
| 4 | Persistence failure keeps previous values and shows `Não foi possível salvar as alterações`. | `test/features/library/domain/services/library_service_test.dart:67-69` — exact failure/message/original book; `test/features/library/presentation/cubit/library_cubit_test.dart:55-57` — exact prior collection plus message. | ✅ |
| 5 | Cancellation returns without metadata mutation. | `test/features/library/presentation/widgets/book_dialogs_test.dart:37-57` — edited input then Cancel returns null payload; `test/widget_test.dart:134-144` — repository still equals exact pre-edit `book`. | ✅ |

### LIB-05 — Delete a complete local book

| # | Spec-defined outcome | Exact evidence (`file:line` + assertion) | Result |
| - | -------------------- | ---------------------------------------- | ------ |
| 1 | Confirmation names the exact book. | `test/features/library/presentation/widgets/book_dialogs_test.dart:72-77` — dialog contains `Title` and confirmation returns true. | ✅ |
| 2 | Cancellation preserves exact record, PDF, and cover. | `test/features/library/presentation/widgets/book_dialogs_test.dart:79-96` — Cancel returns false; `test/widget_test.dart:146-162` — repository equals exact `book`, PDF bytes `[1,2,3]`, cover bytes `[4,5,6]`. | ✅ |
| 3 | Confirmation quarantines files before row removal, then removes row/PDF/cover before visible success. | `test/features/library/domain/services/library_service_test.dart:89-92` — exact quarantine/discard order, row null, deletion observed quarantine; `test/widget_test.dart:176-181` — empty visible library and both files absent. | ✅ |
| 4 | Any owned-file cleanup failure restores row/files and reports `Não foi possível excluir o livro`. | `test/features/library/domain/services/library_service_test.dart:150-157` — exact failure/message/record and both restored paths; `test/widget_test.dart:217-230` — failure survives database restart with exact row/PDF/cover bytes. | ✅ |
| 5 | Successful deletion survives restart with no referenced owned file or quarantine remaining. | `test/widget_test.dart:232-248` — success, reopen file-backed database, row null, PDF/cover absent, `.trash` empty. | ✅ |

**Acceptance status**: ✅ 28/28 criteria match spec-defined values; 0 uncovered; 0 spec-precision gaps.

## Edge Cases

| Edge case | Exact evidence | Result |
| --------- | -------------- | ------ |
| Filename `.pdf` becomes `Livro sem título`. | `test/features/library/domain/entities/book_test.dart:20` — exact equality. | ✅ |
| Empty readable PDF imports. | `test/features/import_book/data/services/local_book_file_storage_test.dart:31-34` — exact empty-input SHA-256. | ✅ |
| Source disappearance during copy removes stage and produces standard import failure. | `test/features/import_book/data/services/local_book_file_storage_test.dart:276-317` — injected mid-stream `FileSystemException`, exact propagated shape, staging directory empty; `test/features/import_book/domain/services/import_book_service_test.dart:87-120` — disappearance point maps to standard error and compensation. | ✅ |
| Disk-full-shaped write failure removes stage and leaves repository unchanged. | `test/features/import_book/data/services/local_book_file_storage_test.dart:278-317` — injected OS error 28 and empty stage; `test/features/import_book/domain/services/import_book_service_test.dart:87-120` — disk-full point yields exact standard error, no partial/insert. | ✅ |
| Import/edit/replacement/deletion each emits exactly one ordered collection with no duplicate IDs. | `test/features/library/data/repositories/drift_book_repository_test.dart:177-243` — exact emission lists/count after every mutation, ordered IDs, set equality. | ✅ |
| Empty cover skips cover file quarantine but deletes PDF and row. | `test/features/library/domain/services/library_service_test.dart:162-176` — success, row null, quarantined paths exactly `[storedFilePath]`, requested cover remains `''`. | ✅ |
| Already-missing owned file counts as deleted. | `test/features/import_book/data/services/local_book_file_storage_test.dart:233-235` — missing owned path completes without exception. | ✅ |

## Discrimination Sensor

Mutations ran only in disposable `/tmp/vox-library-verify2.v7IeKm`; the real implementation and tests were not mutated.

| Mutation | Production location | Fault injected | Result |
| -------- | ------------------- | -------------- | ------ |
| M1 — cleanup compensation | `lib/features/library/domain/services/library_service.dart:83-85` | On permanent quarantine cleanup failure, returned success and skipped restoration. | ✅ Killed by `library_service_test.dart:150` and `widget_test.dart:223` (`success` had to be false); both failed. |
| M2 — off-UI isolate route | `lib/features/import_book/data/services/local_book_file_storage.dart:25` | Forced `_useIsolate = false`, routing production hash/copy through the caller isolate. | ✅ Killed by `local_book_file_storage_test.dart:60` (`workerIdentities` expected length 2, actual 0). |
| M3 — owned-cover lifecycle | `lib/features/library/domain/services/library_service.dart:71` | Passed null cover path during quarantine, silently excluding an owned cover from cleanup/restoration. | ✅ Killed by `library_service_test.dart:153` (expected restored cover+PDF, actual PDF only). |

An exploratory change to the concrete adapter's empty-cover condition survived a fake-service test because that test did not traverse the adapter. It was rejected as a non-applicable probe, not counted as a valid mutation, and replaced by M3 above.

**Sensor depth**: lightweight, three required high-risk behavior mutations
**Result**: ✅ 3/3 valid mutants killed; 0 survived.

## F1–F4 Closure, Payload Conjunction, and Test Necessity

- **F1**: Closed. Cleanup failure asserts the exact failure payload, exact restored row/files, and durable restart conjunction; successful retry asserts row/PDF/cover/trash absence after restart.
- **F2**: Closed. The production default path records two worker isolate identities and jointly asserts exact hash/copy payloads and caller/worker inequality.
- **F3**: Closed. All status labels, current input values, cancellation payloads and unchanged persistence, fresh-app persistence/order/default layout, visible order, and `<2s` latency are asserted.
- **F4**: Closed. Real stream-shaped disappearance and OS-error-28 payloads assert stage cleanup and service compensation; empty cover and exact one-emission-per-mutation behavior are asserted.
- **Payload rule**: Covered tests assert whole `Book` values, exact strings, exact state sequences, exact file bytes/paths, exact order/counts, exact timestamps, and exact isolate identities—not only call occurrence.
- **Conjunction rule**: Restart + persistence + ordering + default layout + visibility + latency are joined in one test; cleanup failure + compensation + restart and deletion success + permanent cleanup + restart are each joined in one lifecycle.
- **Test necessity**: M1–M3 prove the newly added F1/F2/F3/F4 assertions discriminate the required behavior. All in-scope tests claim an AC, edge case, schema/migration rule, task done-when, or application composition contract. No weakened assertion or unjustified test deletion was found.

## Gate Check

- **Command**: `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug`
- **Result**: ✅ PASS
- **Build runner**: 184 Drift inputs and 92 combining-builder inputs checked; 0 outputs changed
- **Analyze**: 0 issues
- **Tests after feature**: 112 passed, 0 failed, 0 skipped
- **Tests before feature (`e40c552`)**: 24
- **Delta**: +88
- **APK**: debug APK built successfully

## Code Quality

| Principle | Status |
| --------- | ------ |
| No features beyond requested scope | ✅ |
| No single-use abstraction or unnecessary flexibility | ✅ |
| Surgical feature-scoped changes; no unrelated refactor | ✅ |
| Matches repository/Cubit/Drift/widget patterns | ✅ |
| Assertions are spec-anchored and non-shallow | ✅ |
| Domain 1:1 mapping and route/widget happy-edge-error coverage | ✅ |
| Every in-scope test has a requirement/edge/done-when claim | ✅ |
| Guidelines followed: `analysis_options.yaml`, `.github/workflows/ci.yml`, `docs/spec.md` | ✅ |
| Senior-engineer approval | ✅ |

## Requirement Traceability

| Requirement | Previous validation | Iteration-2 status |
| ----------- | ------------------- | ------------------ |
| LIB-01 | Needs fix | ✅ Verified |
| LIB-02 | Verified | ✅ Verified |
| LIB-03 | Needs fix | ✅ Verified |
| LIB-04 | Needs fix | ✅ Verified |
| LIB-05 | Needs fix | ✅ Verified |

## Summary

**Overall**: ✅ Ready

**Spec-anchored check**: 28/28 acceptance criteria matched; 0 gaps
**Edges**: 7/7 matched
**Sensor**: 3/3 valid mutants killed
**Gate**: 112 passed, 0 failed, 0 skipped; analysis and debug APK build passed

No grounded failure signal remains, so iteration 2 adds no lesson and no fix plan.

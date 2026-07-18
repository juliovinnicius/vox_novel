# Visual Reader Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `spec-driven-development` skill: **activate it by
name and follow its Execute flow and Critical Rules.** The skill is the source
of truth for the per-task cycle, gate, test-adequacy review, atomic commit,
worker batching, and independent Verifier.

**If the skill cannot be activated, STOP and tell the user — do not proceed
without it.**

---

**Design**: `.specs/features/visual_reader/design.md`
**Status**: In Progress

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before
> Execute. Guidelines found: `.github/workflows/ci.yml`,
> `analysis_options.yaml`, `docs/spec.md`; existing Flutter tests were sampled
> for framework, style, and location. Strong defaults apply to every acceptance
> criterion and listed edge case because the project defines no lower coverage
> threshold.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Reader entities and position resolver | unit | All branches; 1:1 mapping to READ-01–05 domain outcomes and every mapping/bounds/stale edge | `test/features/visual_reader/domain/**/*_test.dart` | `flutter test test/features/visual_reader/domain` |
| Drift schema and repository | integration | Fresh v4, v3 migration retention, exact round trips, errors, active-run filter, adversarial ordering, cascade, serialized newest-wins | `test/features/visual_reader/data/**/*_test.dart`, `test/core/database/app_database_test.dart` | `flutter test test/features/visual_reader/data test/core/database/app_database_test.dart` |
| VisualReaderCubit | unit | Every state transition, exact messages, settings bounds, text/PDF mapping, stale repair, ordering, and close lifecycle | `test/features/visual_reader/presentation/cubit/**/*_test.dart` | `flutter test test/features/visual_reader/presentation/cubit` |
| Reader widgets/pages | widget | Exact rendered values, happy/empty/error/boundary states, semantics, highlight, theme/font, PDF callbacks, lazy rendering, rotation | `test/features/visual_reader/presentation/**/*_test.dart` | `flutter test test/features/visual_reader/presentation` |
| Library/router/composition | widget/integration | Ready-only open affordance, route path/ID, back/unavailable, singleton/factory disposal and injected PDF seam | `test/features/library/presentation/**/*_test.dart`, `test/app/**/*_test.dart` | `flutter test test/features/library/presentation test/app` |
| Root reader flow | integration/widget | Complete seed→open→navigate/settings/PDF→restart restore→delete cascade plus failure and responsiveness paths | `test/features/visual_reader/visual_reader_integration_test.dart` | `flutter test test/features/visual_reader/visual_reader_integration_test.dart` |
| Generated Drift/config | none | Build gate and generated-code consistency | `lib/core/database/app_database.g.dart` | build gate only |

## Gate Check Commands

> Generated from `.github/workflows/ci.yml` and existing focused-test patterns.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | Domain, Cubit, or isolated widget task | `flutter test <focused-test-path>` |
| Full | Schema, repository, route, DI, or integration task | `flutter analyze && flutter test` |
| Build | End of every phase and final implementation | `flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are sequential; tasks within a phase execute in order.

### Phase 1: Domain and durable data

```text
T1 → T2 → T3
```

### Phase 2: Reader state machine

```text
T3 → T4 → T5 → T6
```

### Phase 3: Reading surfaces

```text
T6 → T7 → T8 → T9 → T10
```

### Phase 4: Route and complete application flow

```text
T10 → T11 → T12 → T13 → T14
```

---

## Task Breakdown

### T1: Define reader domain models and position mapping

**What**: Create validated reader settings, visual position, aggregate/chapter
models, enums, and the pure text↔PDF/stale-position resolver.
**Where**:
`lib/features/visual_reader/domain/entities/reader_models.dart`,
`lib/features/visual_reader/domain/services/reader_position_resolver.dart`
**Depends on**: None
**Reuses**: `Book`, `ChapterDraft`, `NarrationBlockDraft`
**Requirement**: READ-01, READ-02, READ-03, READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Defaults and every theme/family/size/line-height bound are exact.
- [ ] Aggregates reject invalid order, ownership, and active-content shape.
- [ ] Text→PDF and PDF→text mapping covers blocks, empty chapters, no match, adversarial IDs, and one-based page bounds.
- [ ] Stale/cross-chapter positions resolve to the exact first valid fallback.
- [ ] Domain tests satisfy every applicable spec AC/edge and quick gate passes.

**Tests**: unit
**Gate**: quick, then build
**Commit**: `feat(reader): define visual reader domain`

### T2: Add reader settings and position schema

**What**: Add Drift tables, converters, schema-v4 migration, generated output,
and exact migration/cascade tests.
**Where**:
`lib/features/visual_reader/data/database/reader_settings.dart`,
`lib/features/visual_reader/data/database/reader_positions.dart`,
`lib/core/database/app_database.dart`,
`lib/core/database/app_database.g.dart`,
`test/core/database/app_database_test.dart`,
`test/features/visual_reader/data/database/reader_schema_test.dart`
**Depends on**: T1
**Reuses**: `UtcDateTimeConverter`, books foreign-key pattern
**Requirement**: READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Fresh schema creates exactly one settings boundary and one position per book.
- [ ] Version 3 upgrades to 4 without changing seeded book/run/page/chapter/block payloads.
- [ ] Invalid raw enum/bound values fail through typed conversion/validation.
- [ ] Deleting a book cascades its position while global settings remain.
- [ ] Build runner output is current and full gate passes.

**Tests**: integration
**Gate**: full, then build
**Commit**: `feat(reader): persist reader settings and positions`

### T3: Implement the visual reader repository

**What**: Add the repository contract and Drift implementation for exact active
content, settings, and position operations with source ordering.
**Where**:
`lib/features/visual_reader/domain/repositories/visual_reader_repository.dart`,
`lib/features/visual_reader/data/repositories/drift_visual_reader_repository.dart`,
`test/features/visual_reader/data/repositories/drift_visual_reader_repository_test.dart`
**Depends on**: T2
**Reuses**: `AppDatabase`, active-run schema and repository test fixtures
**Requirement**: READ-01, READ-02, READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Only a ready book's current active run becomes a reader aggregate.
- [ ] Chapters and blocks return by numeric source order with adversarial IDs.
- [ ] Missing/not-ready/stale-active content returns null without partial aggregates.
- [ ] Settings and positions round-trip every exact field via complete upserts.
- [ ] Position writes invoked concurrently for one book are serialized and newest requested value wins.
- [ ] Query/save errors propagate without exposing content; integration tests and build gate pass.

**Tests**: integration
**Gate**: full, then build
**Commit**: `feat(reader): implement durable reader repository`

### T4: Implement reader loading and validated restoration

**What**: Create reader state and the Cubit's load/unavailable/default/stale
repair lifecycle.
**Where**:
`lib/features/visual_reader/presentation/cubit/visual_reader_state.dart`,
`lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart`,
`test/features/visual_reader/presentation/cubit/visual_reader_cubit_test.dart`
**Depends on**: T3
**Reuses**: immutable Cubit state/error conventions, `ReaderPositionResolver`
**Requirement**: READ-01, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Load emits exact loading→ready state with defaults or valid saved state.
- [ ] Missing/not-ready/invalid content emits exact unavailable state/message.
- [ ] Stale text IDs and out-of-range PDF pages repair to exact valid positions and persist the repair.
- [ ] Load/settings failures use specified fallback/messages without content leakage.
- [ ] Duplicate/late load results cannot overwrite a newer book request.
- [ ] Cubit tests cover every load branch and quick gate passes.

**Tests**: unit
**Gate**: quick, then build
**Commit**: `feat(reader): load and restore reader state`

### T5: Add chapter, block, mode, and PDF-page navigation

**What**: Extend the Cubit with exact selection, chapter boundaries,
text↔PDF mapping, page clamping, and ordered position requests.
**Where**:
`lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart`,
`test/features/visual_reader/presentation/cubit/visual_reader_cubit_test.dart`
**Depends on**: T4
**Reuses**: `ReaderPositionResolver`
**Requirement**: READ-01, READ-02, READ-03, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Block/chapter selections preserve exact content and choose correct first/empty block.
- [ ] Previous/next boundaries are no-ops and adjacent navigation is exact.
- [ ] Text→PDF and PDF→text transitions persist full related positions.
- [ ] Repeated selection is idempotent and invalid foreign IDs are ignored.
- [ ] Every state mutation remains readable while persistence is pending.
- [ ] Cubit navigation tests and quick gate pass.

**Tests**: unit
**Gate**: quick
**Commit**: `feat(reader): coordinate reader navigation`

### T6: Add settings transitions and write lifecycle

**What**: Extend the Cubit with bounded theme/typography updates, atomic settings
saves, ordered error handling, and close awaiting the write tail.
**Where**:
`lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart`,
`test/features/visual_reader/presentation/cubit/visual_reader_cubit_test.dart`
**Depends on**: T5
**Reuses**: `ReaderSettings`, Cubit close pattern
**Requirement**: READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Theme/family/line height update only to allowed exact values.
- [ ] Font changes by 2 and cannot pass 14/32.
- [ ] Complete settings persist after each valid change; repeated current value is idempotent.
- [ ] Settings/position write failures retain in-memory state and expose each exact message once.
- [ ] Later writes continue after an earlier failure and close awaits all pending work.
- [ ] Cubit lifecycle tests pass and phase build gate passes.

**Tests**: unit
**Gate**: quick, then build
**Commit**: `feat(reader): persist reader presentation state`

### T7: Build the lazy text reader view

**What**: Render one chapter with exact lazy ordered blocks, selected
visual/semantic state, tap selection, empty state, wrapping, and boundary controls.
**Where**:
`lib/features/visual_reader/presentation/widgets/text_reader_view.dart`,
`test/features/visual_reader/presentation/widgets/text_reader_view_test.dart`
**Depends on**: T6
**Reuses**: Material semantics and stable `ValueKey` patterns
**Requirement**: READ-01, READ-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Chapter title and every block appear exactly once in numeric order with unchanged Unicode text.
- [ ] Only current block has exact visual and semantic selection; tap emits its ID.
- [ ] Empty chapter shows only the exact empty message.
- [ ] Previous/next callbacks and disabled boundaries are exact.
- [ ] A large fixture proves off-screen blocks are not eagerly built and frames pump.
- [ ] Rotation/narrow viewport produces no horizontal overflow; widget tests pass.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(reader): render reformatted chapter text`

### T8: Build accessible chapter navigation

**What**: Add the end-drawer chapter list with exact order/current semantics and
selection closure behavior.
**Where**:
`lib/features/visual_reader/presentation/widgets/chapter_drawer.dart`,
`test/features/visual_reader/presentation/widgets/chapter_drawer_test.dart`
**Depends on**: T7
**Reuses**: Material drawer/list selection patterns
**Requirement**: READ-02

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Each exact chapter title renders once in source order.
- [ ] Exactly one current chapter has selected accessibility state.
- [ ] Tap returns exact chapter ID and closes the drawer.
- [ ] Empty/single/many chapter fixtures remain accessible.
- [ ] Widget tests and quick gate pass.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(reader): add chapter navigation drawer`

### T9: Build settings controls and reader palettes

**What**: Add the settings sheet and exact light/sepia/dark surface palettes
with bounded typography controls.
**Where**:
`lib/features/visual_reader/presentation/widgets/reader_settings_sheet.dart`,
`lib/features/visual_reader/presentation/theme/reader_theme.dart`,
`test/features/visual_reader/presentation/widgets/reader_settings_sheet_test.dart`,
`test/features/visual_reader/presentation/theme/reader_theme_test.dart`
**Depends on**: T8
**Reuses**: Material controls, domain settings bounds
**Requirement**: READ-04

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Controls expose exact current values and accessible labels.
- [ ] Size actions disable exactly at 14/32 and emit increments of 2.
- [ ] Only allowed themes, families, and line heights can be emitted.
- [ ] Three palettes meet normal-text contrast and visibly distinguish selected blocks.
- [ ] Typography applies exact size/family/height without navigation.
- [ ] Widget/theme tests and quick gate pass.

**Tests**: widget/unit
**Gate**: quick
**Commit**: `feat(reader): add reader appearance controls`

### T10: Isolate the original PDF surface

**What**: Add the testable original-PDF view and production `pdfrx` adapter with
page label/callback/controller/error behavior.
**Where**:
`lib/features/visual_reader/presentation/widgets/original_pdf_view.dart`,
`test/features/visual_reader/presentation/widgets/original_pdf_view_test.dart`
**Depends on**: T9
**Reuses**: verified `pdfrx 2.4.7` viewer/controller/params APIs
**Requirement**: READ-03

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Production adapter opens exact path and one-based initial page.
- [ ] Page changes update exact `Página X de Y` and emit valid pages only.
- [ ] State-driven page changes use the controller without callback loops.
- [ ] Missing/corrupt/zero-page input shows exact PDF error while switch-to-text remains enabled.
- [ ] Fake surface tests cover load/change/error without native engine dependency.
- [ ] Widget tests and phase build gate pass.

**Tests**: widget
**Gate**: quick, then build
**Commit**: `feat(reader): add original PDF surface`

### T11: Compose the ReaderPage

**What**: Build the route scaffold joining Cubit, text/PDF surfaces, drawer,
settings, transient messages, unavailable/back state, and scroll restoration.
**Where**:
`lib/features/visual_reader/presentation/pages/reader_page.dart`,
`test/features/visual_reader/presentation/pages/reader_page_test.dart`
**Depends on**: T10
**Reuses**: BlocProvider/Listener patterns, all Phase 3 widgets
**Requirement**: READ-01, READ-02, READ-03, READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Loading, ready text/PDF, empty chapter, PDF error, and unavailable states are exact.
- [ ] App bar shows exact title and accessible mode/chapter/settings controls.
- [ ] Cubit state drives all child views and messages are shown/cleared once.
- [ ] Restored/new selection scrolls into view after layout without altering state.
- [ ] Rotation preserves mode/chapter/block/page/settings.
- [ ] Page widget tests satisfy all relevant ACs and quick gate passes.

**Tests**: widget
**Gate**: quick
**Commit**: `feat(reader): compose visual reader page`

### T12: Open ready books through the reader route

**What**: Add ready-only open affordances to list/grid/library and the injected
`/reader/:bookId` route with exact back/unavailable behavior.
**Where**:
`lib/features/library/presentation/widgets/book_list_item.dart`,
`lib/features/library/presentation/widgets/book_grid_item.dart`,
`lib/features/library/presentation/pages/library_page.dart`,
`lib/app/router/app_router.dart`,
corresponding library/router tests
**Depends on**: T11
**Reuses**: existing action callbacks, GoRouter builder seam
**Requirement**: READ-01, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Ready list/grid items expose exact accessible open action; other statuses cannot open.
- [ ] Activating a ready book navigates exactly to its encoded `/reader/:bookId`.
- [ ] Router passes decoded exact ID to injected reader builder.
- [ ] System/app-bar back returns to library.
- [ ] Route happy, invalid ID, direct deep link, and unavailable paths pass widget tests.
- [ ] Full gate passes.

**Tests**: widget/integration
**Gate**: full
**Commit**: `feat(reader): route ready books to reader`

### T13: Register and dispose reader dependencies

**What**: Register the reader repository and route-scoped Cubit construction,
wire production PDF surface, and guarantee reset/route disposal awaits writes.
**Where**:
`lib/app/dependency_injection/configure_dependencies.dart`,
`lib/main.dart`,
`test/app/dependency_injection/configure_dependencies_test.dart`,
`test/widget_test.dart` bootstrap seam
**Depends on**: T12
**Reuses**: GetIt singleton disposal and application configurator patterns
**Requirement**: READ-01, READ-03, READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] One Drift reader repository is registered and reused.
- [ ] Every reader route gets a book-specific Cubit that loads once and closes once.
- [ ] Tests can inject repository, Cubit, clock, and PDF surface without native/global calls.
- [ ] Reset/route pop awaits a pending latest position write before database closure.
- [ ] Repeated configure calls remain idempotent; composition tests and full gate pass.

**Tests**: integration
**Gate**: full
**Commit**: `feat(app): compose visual reader dependencies`

### T14: Verify the complete durable reader flow

**What**: Add one cohesive application integration proving open, exact text,
selection, chapters, settings, PDF mapping, restart restore, stale repair,
failure isolation, responsiveness, and deletion cascade.
**Where**:
`test/features/visual_reader/visual_reader_integration_test.dart`
**Depends on**: T13
**Reuses**: file-backed Drift/root-test fixtures and injected PDF surface
**Requirement**: READ-01, READ-02, READ-03, READ-04, READ-05

**Tools**:

- MCP: NONE
- Skill: `spec-driven-development`

**Done when**:

- [ ] Seeded ready book opens from library and renders exact ordered text.
- [ ] Paragraph/chapter selection and text↔PDF page mapping persist exact identities.
- [ ] Theme/typography and per-book mode/position survive database/app restart.
- [ ] Stale active-run IDs repair to first valid content and persist the repair.
- [ ] Missing PDF leaves text usable; unavailable content returns safely.
- [ ] Pending saves allow frames/state reads and close/reset awaits cleanup.
- [ ] Deleting the book removes its position but preserves global settings.
- [ ] Suite declaration count does not decrease; full build gate passes.

**Tests**: integration/widget
**Gate**: full, then build
**Commit**: `test(reader): verify complete visual reader flow`

---

## Phase Execution Map

```text
Phase 1 → Phase 2 → Phase 3 → Phase 4

Phase 1: T1 → T2 → T3
Phase 2: T3 → T4 → T5 → T6
Phase 3: T6 → T7 → T8 → T9 → T10
Phase 4: T10 → T11 → T12 → T13 → T14
```

Execution is strictly sequential. Cross-phase anchors (`T3`, `T6`, `T10`) are
shown once as the preceding phase output and once as the next phase dependency;
they are not executed twice.

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | Cohesive domain model + pure resolver boundary | ✅ Granular |
| T2 | One schema/migration deliverable | ✅ Granular |
| T3 | One repository contract/implementation | ✅ Granular |
| T4 | One Cubit loading lifecycle | ✅ Granular |
| T5 | One Cubit navigation lifecycle | ✅ Granular |
| T6 | One Cubit settings/write lifecycle | ✅ Granular |
| T7 | One text-view component | ✅ Granular |
| T8 | One chapter-drawer component | ✅ Granular |
| T9 | One settings/theme component boundary | ✅ Cohesive |
| T10 | One PDF-surface component boundary | ✅ Granular |
| T11 | One route page composition | ✅ Granular |
| T12 | One navigation/open integration | ✅ Cohesive |
| T13 | One application composition integration | ✅ Cohesive |
| T14 | One complete root-flow verification | ✅ Cohesive |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | phase start | ✅ Match |
| T2 | T1 | T1 → T2 | ✅ Match |
| T3 | T2 | T2 → T3 | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | T4 | T4 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 | ✅ Match |
| T7 | T6 | T6 → T7 | ✅ Match |
| T8 | T7 | T7 → T8 | ✅ Match |
| T9 | T8 | T8 → T9 | ✅ Match |
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | T10 | T10 → T11 | ✅ Match |
| T12 | T11 | T11 → T12 | ✅ Match |
| T13 | T12 | T12 → T13 | ✅ Match |
| T14 | T13 | T13 → T14 | ✅ Match |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Domain models/resolver | unit | unit | ✅ OK |
| T2 | Schema/migration | integration + build | integration | ✅ OK |
| T3 | Repository | integration | integration | ✅ OK |
| T4 | Cubit loading | unit | unit | ✅ OK |
| T5 | Cubit navigation | unit | unit | ✅ OK |
| T6 | Cubit persistence/settings | unit | unit | ✅ OK |
| T7 | Text widget | widget | widget | ✅ OK |
| T8 | Drawer widget | widget | widget | ✅ OK |
| T9 | Settings/theme widgets | widget/unit | widget/unit | ✅ OK |
| T10 | PDF widget adapter | widget | widget | ✅ OK |
| T11 | Reader page | widget | widget | ✅ OK |
| T12 | Library/router | widget/integration | widget/integration | ✅ OK |
| T13 | Composition | integration | integration | ✅ OK |
| T14 | Root flow | integration/widget | integration/widget | ✅ OK |

Every test-bearing layer is tested in the same task that changes it; no tests
are deferred to a later task.

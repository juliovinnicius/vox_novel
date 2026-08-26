# STATE

## Decisions

### AD-001
- **Decision**: Organize application code feature-first, adding data/domain/presentation sublayers only when a feature needs them.
- **Reason**: Preserve the separation required by the product specification without creating empty Clean Architecture ceremony.
- **Trade-off**: Feature folders will not all have identical subdirectories at project start.
- **Scope**: All Dart application features and shared application infrastructure.
- **Date**: 2026-07-17
- **Status**: active

### AD-002
- **Decision**: Use Cubit through `flutter_bloc` for mutable presentation state.
- **Reason**: The user selected Cubit for its direct method-driven state transitions.
- **Trade-off**: Complex event streams may later require explicit coordination outside event-based BLoC classes.
- **Scope**: All presentation-state management.
- **Date**: 2026-07-17
- **Status**: active

### AD-003
- **Decision**: Use `get_it` through a single application composition root.
- **Reason**: It isolates dependency construction without introducing a second state-management system.
- **Trade-off**: Service location must remain confined to composition boundaries to avoid hidden dependencies.
- **Scope**: Runtime dependency registration and test composition.
- **Date**: 2026-07-17
- **Status**: active

### AD-004
- **Decision**: Use `go_router` as the application navigation abstraction.
- **Reason**: The user selected declarative URL-based routing from the foundation onward.
- **Trade-off**: Navigation depends on an additional package and Router API conventions.
- **Scope**: All application navigation.
- **Date**: 2026-07-17
- **Status**: active

### AD-005
- **Decision**: Use Drift as the local relational persistence abstraction and keep tables owned by their product features.
- **Reason**: The product requires offline, transactional persistence while feature ownership avoids a monolithic database layer.
- **Trade-off**: Schema changes require code generation and coordinated migrations.
- **Scope**: All persisted relational application data.
- **Date**: 2026-07-17
- **Status**: active

### AD-006
- **Decision**: Gate GitHub changes with Flutter analysis, the complete test suite, and an Android debug APK build.
- **Reason**: The user explicitly required all three checks in GitHub Actions.
- **Trade-off**: CI takes longer than analysis and tests alone.
- **Scope**: GitHub Actions continuous integration for the Android-first MVP.
- **Date**: 2026-07-17
- **Status**: active

### AD-007
- **Decision**: Persist visual reader position separately from narration/playback progress.
- **Reason**: Browsing text or PDF must not silently advance or rewind the durable audio position introduced by Milestone 4.
- **Trade-off**: The application stores and coordinates two related position models instead of one shared record.
- **Scope**: Visual reader, narration, playback restoration, and book deletion lifecycle.
- **Date**: 2026-07-18
- **Status**: active

### AD-008
- **Decision**: Keep one foreground narration engine behind a package-agnostic adapter and coordinate it with a narration-specific route Cubit.
- **Reason**: Engine callbacks, queue state, and narration progress must remain testable and separate from visual reading while allowing Milestone 5 to replace foreground ownership with a media service.
- **Trade-off**: Reader composition coordinates two Cubits and an engine registry instead of one combined state object.
- **Scope**: Narration, reader integration, application lifecycle, and future background media playback.
- **Date**: 2026-07-18
- **Status**: active

### AD-009
- **Decision**: Split content sources by shape — paged sources (PDF) stay batch-processed, chaptered sources (web) are ingested incrementally — and route both through one shared `ChapterIngest` collaborator that owns clean-text-to-blocks persistence.
- **Reason**: A source that supplies its own chapter index must become readable chapter by chapter, which the whole-document batch barrier cannot deliver, while the ingest core must never fork between sources.
- **Trade-off**: Two orchestrators exist over one ingest core, and processing runs gain an "active but still growing" state.
- **Scope**: All content ingestion, processing-run lifecycle, and future content sources.
- **Date**: 2026-08-17
- **Status**: active

### AD-010
- **Decision**: Confine all outbound network access to a single polite-fetcher adapter that throttles per host, honors `Retry-After`, sends a descriptive app User-Agent, and refuses redirects that leave the configured host; domain services never perform I/O directly.
- **Reason**: Politeness and rate limiting must be impossible to bypass, and tests must run without network access.
- **Trade-off**: Every network-dependent feature must route through one adapter interface instead of calling an HTTP client where convenient.
- **Scope**: All outbound HTTP from the application.
- **Date**: 2026-08-17
- **Status**: active

### AD-011
- **Decision**: Keep AD-009's ingest-core boundary and amend WEB-06 AC1 to match, rather than build the generic `ContentSource` seam the AC originally demanded.
- **Reason**: The AC predated AD-009. AD-009 already delivers the story's goal — adding a source does not fork the pipeline — through one shared `ChapterIngest`; satisfying the AC literally would mean refactoring the settled PDF path and revoking AD-009.
- **Trade-off**: `TextProcessingService` keeps `PdfTextExtractor`, so "the processing service references no PDF-specific types" is knowingly not true; only the ingest core is source-agnostic, and an architecture test now enforces that narrower promise.
- **Scope**: Content ingestion boundaries and any future content source.
- **Date**: 2026-08-19
- **Status**: active

### AD-012
- **Decision**: A user cancel of a web download is session-scoped; the startup resume re-enqueues the book on the next launch.
- **Reason**: WEB-11 AC5's success criterion — a thousand-chapter novel completing across restarts — depends on an unconditional resume, and a durable paused state would need new book/queue state, a resume affordance, and a migration.
- **Trade-off**: A deliberate cancel is undone by relaunching the app; the user accepted this on 2026-08-26 pending real use.
- **Scope**: Web download queue lifecycle.
- **Date**: 2026-08-26
- **Status**: active


## Handoff

- **Feature**: web_source_import / `.specs/features/web_source_import`
- **Phase / Task**: Validate — Verifier iteration 3 returned PASS; feature complete on its branch
- **Completed**: T1–T24, T27–T28, fixes F1–F5, hardening V1–V2; 613 tests, analyze clean, debug APK builds
- **In-progress** (file:line): none
- **Next step**: merge `feat/web-source-import` into `main`; decide whether a cancelled web book stays cancelled across a restart (`resumePending` re-enqueues it today; WEB-11 AC5/AC6 are silent); no UAT script exists for this feature
- **Blockers**: none
- **Uncommitted files**: none
- **Branch**: `feat/web-source-import` (42 commits ahead of `main`)
- **Note**: `validation.md` covers `69ad930..c58d705`; the later `f531da5` (ingest-core import scan) postdates the report

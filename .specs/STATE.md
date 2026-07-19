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

## Handoff

- **Feature**: narration / `.specs/features/narration`
- **Phase / Task**: Execute — Phase 1, T1 next
- **Completed**: Milestones 1–3; Milestone 4 specification, design, and tasks approved
- **In-progress** (file:line): `.specs/features/narration/tasks.md:79`
- **Next step**: execute Phase 1 tasks T1–T5; run combined Milestone 3–4 UAT after automated validation
- **Blockers**: none
- **Uncommitted files**: Milestone 4 planning documents
- **Branch**: `main`

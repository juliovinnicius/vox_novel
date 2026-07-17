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

## Handoff

- **Feature**: library_import / `.specs/features/library_import`
- **Phase / Task**: Milestone 1 complete — validation iteration 2 PASS
- **Completed**: T1 through T14, fixes F1 through F4, 28/28 acceptance criteria and 7/7 edge cases verified
- **In-progress** (file:line): none
- **Next step**: specify Milestone 2 — text processing
- **Blockers**: none
- **Uncommitted files**: `.specs/STATE.md`, `.specs/features/library_import/spec.md`, `.specs/features/library_import/tasks.md`, `.specs/features/library_import/validation.md`
- **Branch**: `main`

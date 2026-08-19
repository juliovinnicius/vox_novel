# CLAUDE.md

Orientações para trabalhar neste repositório. Leia antes de alterar código.

## O projeto

**vox_novel** (Novel Voice Reader) — app Flutter para importar novels (PDF e, no
trabalho atual, fontes web), extrair e limpar o texto, detectar capítulos e
narrá-lo com TTS local, com progresso durável. Foco Android-first, offline.
Especificação de produto: `docs/spec.md` (pt-BR).

## Comandos

```bash
flutter pub get
flutter analyze                       # sem warnings; gate de CI
flutter test                          # suíte completa
flutter test test/features/web_source # subconjunto durante o desenvolvimento
flutter build apk --debug             # terceiro gate de CI
dart run build_runner build --delete-conflicting-outputs   # após mexer em tabelas Drift
```

O CI (`.github/workflows/ci.yml`) roda `analyze` + `test` + `build apk --debug`.
Antes de concluir uma tarefa, rode pelo menos `flutter analyze && flutter test`.

## Arquitetura

Feature-first; sublayers `data/`, `domain/`, `presentation/` só quando a feature
precisa delas (AD-001). Nada de pastas vazias por cerimônia.

```
lib/
  main.dart                 # createApplication(): seams injetáveis para teste
  app/                      # shell: App, AppCubit, router, composition root
  core/database/            # AppDatabase (Drift) — agrega tabelas das features
  features/<feature>/
    domain/{entities,repositories,services}/    # puro Dart, sem I/O
    data/{database,repositories,services}/      # tabelas Drift e adapters
    presentation/{cubit,pages,widgets,theme}/
```

Features atuais: `library`, `import_book`, `pdf_processing`, `visual_reader`,
`narration`, `content_ingestion` (núcleo compartilhado), `web_source` (em curso).

### Regras estruturais (têm teste que as trava)

- **Cubit, nunca Bloc por eventos** (AD-002). `test/architecture/foundation_architecture_test.dart` falha se um `extends Bloc<` aparecer em `lib/app` ou `lib/main.dart`.
- **Composition root único** — `lib/app/dependency_injection/configure_dependencies.dart` com `get_it` (AD-003). Service locator só nas bordas de composição; nunca `GetIt.instance` dentro de domain/presentation.
- **Toda registração é guardada por `if (!locator.isRegistered<T>())`** e a maioria tem parâmetro opcional correspondente. É assim que os testes injetam fakes: registre antes ou passe pelo parâmetro. Mantenha esse padrão ao adicionar dependências.
- **Navegação por `go_router`** (AD-004), rotas em `lib/app/router/app_router.dart` com builders injetáveis.
- **Persistência por Drift**, tabelas pertencem à feature que as usa (AD-005).
- **Ingestão de conteúdo passa por `ChapterIngest`** (`features/content_ingestion`) — fonte paginada (PDF) entrega o documento inteiro, fonte capitulada (web) entrega capítulo a capítulo, mas o caminho de persistência texto→blocos é único (AD-009). Não bifurque por fonte.
- **Rede só pelo adapter `WebFetcher`** (`features/web_source/domain/services/web_fetcher.dart`, impl. `PoliteWebFetcher`) (AD-010): throttling por host, `Retry-After`, User-Agent descritivo, recusa de redirect para outro host. Domain services nunca fazem I/O direto e testes nunca tocam a rede.

Todas as decisões arquiteturais vivem em `.specs/STATE.md` como `AD-00x`. Ao
tomar uma decisão nova e duradoura, registre-a lá.

## Banco de dados

`lib/core/database/app_database.dart`, `schemaVersion` atual **6**.
Ao adicionar uma tabela:

1. Declare em `features/<feature>/data/database/<tabela>.dart`.
2. Registre em `@DriftDatabase(tables: [...])`.
3. Incremente `schemaVersion` e **acrescente** um bloco `if (from < N)` em `onUpgrade` — nunca edite blocos antigos.
4. `dart run build_runner build --delete-conflicting-outputs` (o `app_database.g.dart` é versionado; demais `*.g.dart` são excluídos do analyzer).
5. Cubra a migração em `test/features/**/data/database/*_test.dart` com dados semeados na versão anterior.

`PRAGMA foreign_keys = ON` no `beforeOpen`; constraints reais (`CHECK`,
`references(..., onDelete: KeyAction.cascade)`) são a norma — prefira travar
invariantes no schema, não só no Dart.

## Convenções de código

- `final class` para entidades, states e services; injeção por construtor nomeado.
- States imutáveis com `copyWith`; campos anuláveis usam a sentinela `const _unset = Object()` para distinguir "não informado" de `null` (ver `library_state.dart`, `book.dart`).
- Entidades validam no construtor e lançam `TextProcessingValidationException`.
- Enums persistidos expõem `storageValue` + `fromStorage` (que lança `FormatException` em valor desconhecido).
- Código, nomes e comentários em inglês; **strings de UI em português** (`'Biblioteca'`, `'Erro de navegação'`).
- Comentário só quando explica um "porquê" não óbvio (ex.: o motivo de um `// ignore:`).

## Testes

Espelham `lib/` em `test/`. Sem pacote de mocking — **fakes escritos à mão**.

- Domain/entities/cubits: unitários, cobrindo cada branch e cada AC da spec.
- Repositórios e migrações: integração contra `NativeDatabase` real em `Directory.systemTemp.createTemp(...)`, com `tearDown` fechando o banco e apagando o diretório.
- Adapters de dados: fake client + fixture salva (`test/fixtures/`), jamais o site real.
- Widgets: render + cada caminho de interação.
- Invariantes de projeto: testes que varrem o fonte em `test/architecture/`.

## Fluxo de trabalho por feature

O projeto usa a skill `tlc-spec-driven`. Cada feature tem
`.specs/features/<nome>/` com `spec.md`, `design.md`, `tasks.md` e
`validation.md`. Quando um `tasks.md` exigir a skill no "Execution Protocol",
ative-a pelo nome e siga o fluxo dela — não improvise.

`.specs/LESSONS.md` e `.specs/lessons.json` são **mantidos por script** — não
edite à mão.

## Commits

Conventional Commits com escopo da feature, em inglês, imperativo e curto:

```
feat(web-source): add polite web fetcher
refactor(processing): extract shared chapter ingest
test(processing): cover Android worker cache propagation
docs(web-source): mark batch 1 complete
```

Um commit atômico por tarefa, com analyze e testes passando.

## Trabalho em andamento

Branch `feat/web-source-import` — importação de novels a partir de sites, guiada
por `.specs/features/web_source_import/`. Receitas por domínio ficam em
`assets/site_recipes.json` (declarado em `pubspec.yaml`) e são carregadas por
`SiteRecipeRegistry`.

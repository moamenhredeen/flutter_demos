# flutter_demos

Pattern lab: experiments to find the best Flutter/library pattern per task, so the findings
can be reused in real apps. Code is disposable; documented findings are the product. Full
rewrites/deletions of feature folders are fine — never preserve code for sentimentality.

## Documentation convention (important)

When an experiment **concludes** (a winner is chosen):

1. Write/update `docs/patterns/<task>.md`: versions + date, options tried (incl. rejected
   ones with their bugs, referenced by commit SHA), verdict, when NOT to use it, and a
   "Rules to carry over" list of portable rules.
2. Give the winning feature folder a `README.md` explaining its mechanics (how this code
   works — not the decision; that lives in the pattern doc). Cross-link both.
3. Update the findings index table in the root `README.md`.
4. Delete rejected implementations from `main` — git history + the pattern doc preserve them.

## Structure

- `lib/data/<api>/` — shared API layer (dio client, models, repository, providers, barrel).
  Demo-agnostic; reused across experiments; every request method takes a `CancelToken`.
- `lib/<feature>/` — one experiment: `<feature>_providers.dart`, `<feature>_screen.dart`,
  `widgets/`, barrel, `README.md`.
- Register new screens in `lib/app_router.dart` and the `_sections` list in
  `lib/home_screen.dart` (subtitle names the pattern demonstrated).

## Tech notes

- Riverpod 3 (3.3.1), manual providers — **no codegen, no build_runner**.
- Riverpod 3 gotchas that shaped past findings: notifiers recreated on rebuild (guard async
  continuations with `ref.mounted`); providers auto-retry failures by default;
  `AsyncValue` keeps previous data during rebuilds (`hasValue` ≠ not refreshing).
- Doc comments at decision points are deliberate (e.g. ordering of `keepAlive`/`onDispose`);
  keep that density when editing.
- `flutter analyze` must stay clean. No test suite currently.

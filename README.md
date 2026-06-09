# flutter_demos

A pattern lab. Each feature folder is an experiment that answers one task-shaped question
("what's the best way to do X in Flutter?"); the conclusions are written down so they can be
carried into real apps. Code here is disposable — the knowledge isn't.

## Findings index

| Task | Verdict | Pattern doc | Live code |
|---|---|---|---|
| Pagination + search (offset APIs) | `(query, page)` family-key providers; no scroll listener, no `loadMore` | [docs/patterns/pagination.md](docs/patterns/pagination.md) | [`lib/book_search/`](lib/book_search/) |

Rejected approaches are documented in the pattern docs and referenced by commit SHA; their
code is deleted from `main`.

## How this repo documents knowledge

Two layers per concluded experiment:

- **`docs/patterns/<task>.md`** — the decision record: options tried (including dead ends and
  their bugs), verdict, when *not* to use it, versions/date, and a "rules to carry over"
  list — the portable part. Survives rewrites and deletions.
- **`lib/<feature>/README.md`** — walkthrough of the winning implementation's mechanics.
  Lives and dies with the code.

Conventions are in [CLAUDE.md](CLAUDE.md).

## Layout

```
lib/
  data/<api>/          shared, demo-agnostic API clients (dio) + models + providers
  <feature>/           one experiment: providers, screen, widgets/, README.md
  widgets/             shared UI (e.g. SearchAppBar)
  home_screen.dart     in-app index of demos
  app_router.dart      go_router routes
docs/patterns/         decision records (the actual product of this repo)
```

Stack: Flutter (Dart SDK ^3.12.1), flutter_riverpod 3.3.1 (no codegen), dio 5.9.2,
go_router 17.3.0.

## Running

```sh
flutter run
```

Home screen lists all demos; each entry names the pattern it demonstrates.

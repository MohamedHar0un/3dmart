---
name: laravel-module
description: Create or extend a 3D Mart Laravel domain module (catalog, orders, promotions, retail media, etc.) following the project's structure, API conventions and test rules. Use when adding a new module, model, action, endpoint, job or policy in apps/platform.
---

# Laravel domain module

Conventions come from `docs/BRIEF.md` §5.2–5.3 and §6. Local commands run through Laravel Sail (`./vendor/bin/sail ...`).

## Layout

```
app/Domain/<Module>/
  Models/        Eloquent models (UUIDv7 keys, casts for money as integer piastres, translatable jsonb)
  Actions/       one public `handle()` per business action; the only place writes happen
  Data/          DTOs for input/output (spatie/laravel-data or readonly classes)
  Events/        domain events fired by actions
  Policies/      authorization per model
  Jobs/          queued work; idempotent; explicit queue name
  Enums/         states and types (backed enums)
app/Http/Controllers/Api/V1/<Audience>/   thin controllers → actions
app/Http/Requests/Api/V1/<Audience>/      validation only
app/Http/Resources/Api/V1/                API resources
database/migrations/                      named <date>_<module>_<what>.php
tests/Feature/<Module>/                   HTTP + action tests
tests/Unit/<Module>/                      pure logic
tests/Arch/                               module boundary rules
```

## Steps

1. Confirm the module's contract in `docs/plan/phase-N.md` (tables, endpoints). If it's missing, stop and report to the lead.
2. Migration first (coordinate with `database-engineer` for anything touching shared tables or extensions).
3. Model, enum, policy. Register the policy.
4. Action(s) with a feature test written first for each acceptance criterion, including the unhappy paths and cross-supplier access.
5. Controller, request, resource. Errors as RFC 9457 problem+json with stable codes; `Idempotency-Key` on writes; cursor pagination on lists; `Accept-Language` for translatable fields.
6. Events and jobs; choose the queue (`payments`, `default`, `notifications`, `media`, `models3d`, `analytics`, `webhooks`).
7. Strings in `lang/en` and `lang/ar` (use the `bilingual-ui` skill).
8. Add an architecture test so other modules can't reach into this module's internals.
9. Run `./vendor/bin/sail pint`, `./vendor/bin/sail php vendor/bin/phpstan`, `./vendor/bin/sail artisan test --parallel`. All green before reporting.

## Don'ts

- No money as float or decimal in PHP; use the Money value object over integer piastres.
- No business logic in controllers, models' boot methods, or observers that hide side effects.
- No changing another module's migration or public contract without the lead's approval.

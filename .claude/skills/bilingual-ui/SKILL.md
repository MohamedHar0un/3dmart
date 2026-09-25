---
name: bilingual-ui
description: Add or change user-facing text and layouts in 3D Mart so they work in Arabic (RTL) and English everywhere - Laravel lang files, Vue (vue-i18n), Flutter (ARB), notifications and emails. Use whenever you add a string, a screen or a component.
---

# Bilingual UI (Arabic + English)

## Strings

- Never hard-code user-facing text. Keys are identical across:
  - Laravel: `lang/en/*.php`, `lang/ar/*.php` (validation, notifications, emails);
  - Vue: `resources/js/i18n/{en,ar}.json`;
  - Flutter: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`.
- Key style: `area.screen.element` (e.g. `checkout.payment.cod_title`).
- Add the English and Arabic value in the same change. If you're unsure of the Arabic, write your best version and flag the key for `localization-specialist` in your report.
- Plurals and numbers through the framework's plural/number APIs, not string concatenation.
- Money: EGP; Arabic shows `ج.م`. Digit style follows decision D10 in `docs/BRIEF.md` §16.

## Layout

- Web: logical properties only (`ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`, `text-start`). No `left`/`right` for layout. Set `dir` and `lang` on `<html>` from the locale.
- Flutter: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`; `Directionality` from the locale.
- Mirror directional icons (back, forward, chevrons, arrows). Don't mirror logos, media controls, charts' time axes, or product images.
- Arabic text runs longer: allow wrapping; never fix widths on text containers.
- Mixed runs (Arabic text + Latin brand + numbers): wrap the Latin/number part in an isolate (`<bdi>` on web, `Directionality`/Unicode isolates in Flutter).

## Checks before you report

- Screens render correctly in both `ar` and `en` (web: Playwright screenshot for each; Flutter: golden test for each).
- No missing keys (run the i18n key check script if present; otherwise diff the key sets).
- For UI work, run the `impeccable` skill's `harden` pass, which covers i18n and overflow edge cases.

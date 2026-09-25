# 3D Mart: business and technical brief

**Audience:** Claude, acting as the lead engineer who builds the whole platform: backend, web frontends, mobile apps, the 3D pipeline and the infrastructure.
**Status:** v1.0 of the brief, 2026-09-25. Decisions marked **Default** below may be revisited by the product owner. Until they are, build to the default.

---

## 0. How to use this brief

1. Read the whole document before writing code. Then read `design/canvas/` in this repo: it is the clickable design (shopper app, supplier dashboard, admin dashboard, proposal, and a Three.js walk-through aisle in `Aisle3D.dc.html`). The design shows intent and UX. It is not production code; don't copy its runtime (`DCLogic`, `support.js`).
2. Work in the phases in §14. Finish each phase's acceptance criteria before starting the next.
3. Record every significant technical decision as an ADR in `docs/adr/NNNN-title.md` (context, decision, consequences).
4. Where this brief says **Ask**, stop and ask the product owner. Everywhere else, make the call, write it down, and keep going.
5. Never commit secrets. Never weaken a test to make it pass. Never skip a phase's security items.

**Kickoff prompt to paste into a new session:**

> You are the lead engineer for 3D Mart. Read `docs/BRIEF.md` fully, then `design/canvas/`. Start Phase 0 from §14. Before you write code, propose the repo layout, the ADRs you will write first, and any **Ask** items that block Phase 0. Then build Phase 0 end to end with tests and CI green.

---

## 1. Business brief

### 1.1 The product

3D Mart is a grocery and FMCG shopping app for Egypt. Its hook is a **3D supermarket**: shoppers walk real-looking aisles on their phone, pick packs off the shelf, turn them in their hand, and add them to the cart. Everything else a modern quick-commerce app needs sits around that: search, cart, checkout with local payment methods, delivery slots and live tracking.

The platform has a second customer: **FMCG suppliers and brands**. They get a portal to manage their catalog, prices and promotions, choose where their products sit on the 3D shelves, buy **retail media** (ads placed inside the 3D store), and see analytics on how shoppers interact with their products.

### 1.2 Users and roles

| Role | Where | What they do |
|---|---|---|
| Shopper | Mobile app (iOS, Android), web shop | Browse in 3D or as a list, search, buy, track orders |
| Supplier user | Supplier portal (web) | Catalog, stock, prices, promotions, shelf planner, ads, analytics, 3D model review |
| Picker | Staff app (mobile) | Pick and pack orders in the store |
| Rider | Staff app (mobile) | Deliver orders, share live location, collect cash on delivery |
| Operations admin | Admin portal (web) | Orders, riders, pickers, delivery zones and slots |
| Catalog / merchandising admin | Admin portal | Categories, planograms, approving supplier changes and 3D models |
| Ads admin | Admin portal | Review and approve ad bookings and creatives |
| Finance admin | Admin portal | Payments, refunds, COD reconciliation, supplier settlements, invoices |
| Super admin | Admin portal | Users, roles, settings, audit log |

### 1.3 Operating model

**Ask (D1).** The RFP doesn't say who holds the stock.
**Default:** a **dark-store model**. The platform runs one or more small warehouses ("dark stores") laid out like the 3D aisles. Suppliers supply stock into them, on consignment or by sale. Every order is picked in one dark store and delivered by platform riders.
- Why: one pickup point per order keeps delivery fast and cheap. It also makes the 3D aisle a faithful copy of a real place.
- Suppliers still get "order received" notifications, per the RFP, for orders containing their products. They also get replenishment requests when stock runs low.
- Build the data model so a second model can be added later without a rewrite: partner supermarkets as fulfilment locations. That means inventory is per **location**, not global.

### 1.4 Revenue streams

1. Product margin or commission on each sale.
2. Delivery fees, with free delivery above a basket threshold.
3. **Retail media**: paid placements inside the 3D store and in search. This is the strategic differentiator; treat its tracking and reporting as first-class.
4. **Paid 3D services for suppliers** (§9.2): AI conversion and artist modelling, bought with model credits. The standard photo → 3D conversion stays free so every supplier can get on the shelves.
5. Supplier analytics subscription tiers (later phase).

### 1.5 Launch scope

- Market: Egypt, starting with Cairo and Giza.
- Languages: Arabic and English, with full right-to-left support. Arabic is the default for new shoppers whose device language is Arabic.
- Currency: EGP. Store money as integer piastres (1 EGP = 100 piastres). Never use floats for money.
- Timezone: `Africa/Cairo` for display and business rules; store timestamps in UTC (`timestamptz`).
- Payments:
  - Paymob: cards, Meeza, mobile wallets.
  - Fawry: reference code paid at an outlet or in the myFawry app.
  - Cash on delivery.

### 1.6 Success metrics

Instrument these from day one; they drive the admin dashboards.

- **Commerce:** conversion rate, average order value, repeat purchase rate at 30 days, cart abandonment.
- **3D engagement:**
  - shelf views per session;
  - pick-up rate (packs picked ÷ shelf views);
  - pick-up → add-to-cart rate;
  - share of sessions using 3D vs the list view.
- **Operations:** order-to-door time (target under 45 minutes for express), fill rate, substitution rate, on-time rate.
- **Retail media:** impressions, taps, add-to-carts, attributed sales, return on ad spend (ROAS) per campaign.
- **Tech:**
  - crash-free sessions ≥ 99.5%;
  - 3D frame rate on the reference device (§7.4);
  - API p95 latency;
  - uptime.

### 1.7 Compliance and legal

Things the RFP doesn't mention but the build must handle:

- **Personal data:** Egypt's Personal Data Protection Law (Law No. 151 of 2020). Consent capture, a privacy policy, data export and deletion requests, a record of processing, least-privilege access, and an audit log of admin access to personal data.
- **Tax:** VAT on invoices. The Egyptian Tax Authority's e-invoice and **e-receipt (B2C)** systems.
  - **Ask (D2):** confirm with the client's accountant which applies and when.
  - Design an `InvoiceIssuer` interface now, with a no-op implementation, so the e-receipt integration can plug in later.
- **App stores:** account deletion inside the app (required by Apple and Google); privacy labels / data-safety forms.
- **Brands and packaging:** suppliers must confirm they own the rights to the photos and brand assets they upload. Add this as a checkbox with a stored timestamp.

---

## 2. Scope

### 2.1 In scope (MVP, Phases 0–7)

- **Shopper mobile app** (Flutter, iOS and Android):
  - onboarding and sign-in (phone number + SMS code, Google, Apple);
  - addresses with a map pin and delivery-zone check;
  - the 3D aisle and a list view fallback;
  - search, product page, cart, checkout (Paymob, Fawry, COD);
  - delivery slots, live order tracking, order history, reorder;
  - push notifications, profile, account deletion.
- **Web shop** (Inertia + Vue): the same catalog, cart and checkout, plus the 3D aisle in the browser.
- **Supplier portal** (Inertia + Vue), matching the Version 1 design:
  - overview analytics, orders received, inventory and prices;
  - promotions, shelf planner, retail media;
  - 3D model review, team members.
- **Admin portal** (Inertia + Vue), matching the Version 1 design:
  - live operations, supplier approvals, ad approvals, riders and pickers;
  - catalog, planograms, delivery zones and slots, promotions;
  - refunds, COD reconciliation, settings, roles, audit log.
- **Staff app** (Flutter, second flavor of the same codebase): picker and rider modes.
- **Photo → 3D pipeline** (n8n + services), §9: the free Standard tier (no AI), plus the paid AI conversion and artist modelling tiers with model credits.
- **Infrastructure** (§10):
  - Kubernetes on Contabo VPS nodes;
  - Cloudflare in front (DNS, proxy, WAF, Tunnel);
  - R2 object storage;
  - CI/CD, monitoring, backups.

### 2.2 Out of scope for MVP (design for, don't build)

- Partner supermarkets as extra fulfilment locations (keep inventory per location).
- Supplier self-serve billing for subscriptions. (Buying model credits for paid 3D services **is** in scope, §9.2.)
- Loyalty points, wallet, referrals.
- AR ("see it on your table"): the GLB assets already make this possible later.
- Customer support chat. Link to WhatsApp for now.

---

## 3. Architecture overview

```
                    ┌──────────────── Cloudflare ────────────────┐
 Shopper app ─┐     │ DNS · WAF · Turnstile · rate limits · cache │
 Staff app ───┼──►  │  app.  api.  supplier.  admin.  ws.        │──► Cloudflare Tunnel ──┐
 Browsers ────┘     │  cdn. (R2 public bucket, custom domain)    │                        │
                    └────────────────────────────────────────────┘                        ▼
                                                               ┌──── Kubernetes (k3s on Contabo) ────┐
                                                               │ Traefik ingress                     │
                                                               │  ├─ laravel-web (Octane) ×N         │
                                                               │  ├─ laravel-reverb (websockets) ×2  │
                                                               │  ├─ laravel-horizon (queues) ×N     │
                                                               │  ├─ laravel-scheduler ×1            │
                                                               │  ├─ n8n main / webhook / workers    │
                                                               │  ├─ mesh-builder (3D service)       │
                                                               │  ├─ PostgreSQL 18 (CloudNativePG ×3)│
                                                               │  ├─ Redis (primary + replica +      │
                                                               │  │   Sentinel)                      │
                                                               │  └─ monitoring: Prometheus, Grafana,│
                                                               │     Loki, Alertmanager              │
                                                               └─────────────────────────────────────┘
     External: Paymob · Fawry · SMS gateway · FCM/APNs · Google Maps · email · Sentry · GPU inference (paid AI tier only)
     Storage:  R2 buckets (public, private, backups)
```

**One Laravel application, several process types.** The same container image runs as:

- `web`: HTTP, serving both the JSON API and the Inertia pages;
- `horizon`: queue workers;
- `reverb`: websockets;
- `scheduler`: scheduled tasks.

This keeps domain logic in one place.

**Default:** a single Laravel app with clear domain modules (§5.2), not microservices. The only separate services are:

- n8n, for workflow orchestration;
- `mesh-builder`, a small service that cleans photos (OpenCV), builds and optimizes 3D models (Node.js for the glTF tooling, with a Python OpenCV worker if cleaner);
- the GPU inference endpoint, which is external and used only by the paid AI tier.

---

## 4. Tech stack and versions

Use the latest stable release of each at build time. Pin exact versions in lock files. Record the chosen versions in ADR-0001.

| Layer | Choice |
|---|---|
| Language (backend) | PHP 8.4 or the newest version the Laravel release supports |
| Framework | Laravel, latest stable major (13.x at the time of writing; use a newer major if one has shipped) |
| App server | Laravel Octane on FrankenPHP |
| Web UI | Inertia.js (latest) + Vue 3 (Composition API, `<script setup>`, TypeScript) + Vite + Tailwind CSS v4. Start from Laravel's official Vue starter kit. |
| UI components | shadcn-vue (ships with the starter kit) + a small in-house design system matching the canvas: Bricolage Grotesque / Figtree / IBM Plex Sans Arabic, green `#1E6B47`, clay `#B4531B`, ground `#F5F2EA` |
| 3D (web) | Three.js in a shared TypeScript package, `packages/aisle-engine` |
| Auth | Laravel Fortify (web: sessions and 2FA) + Laravel Sanctum (mobile: API tokens) + Laravel Socialite (Google, Apple) |
| Authorization | spatie/laravel-permission (roles and permissions) + Laravel policies |
| Queues | Redis + Laravel Horizon |
| Websockets | Laravel Reverb, horizontally scaled over Redis |
| Search | PostgreSQL full-text search + pg_trgm (§6). Meilisearch is the fallback if Arabic relevance isn't good enough (ADR). |
| Media | spatie/laravel-medialibrary on the R2 disk, with conversions run on the queue |
| Money | brick/money (or moneyphp/money) with integer minor units |
| State machines | Enum-backed states with explicit transition classes (e.g., spatie/laravel-model-states) |
| Feature flags | Laravel Pennant |
| Audit | spatie/laravel-activitylog + database triggers for money tables |
| Observability (app) | Laravel Pulse (ops view), Sentry (errors, performance), OpenTelemetry traces (optional) |
| Testing | Pest (unit, feature, architecture tests), Playwright (web E2E), Larastan level 8+, Pint, ESLint + Prettier, `vue-tsc` |
| Mobile | Flutter latest stable, Dart 3; Riverpod, go_router, dio, freezed/json_serializable, flutter_localizations + ARB files, firebase_messaging, google_maps_flutter, webview_flutter (3D, §7.3), sentry_flutter |
| Database | PostgreSQL 18 via the CloudNativePG operator |
| Cache / queues | Redis 8 (Valkey 8 is an acceptable drop-in; record in an ADR) |
| Workflows | n8n (self-hosted, queue mode) |
| Kubernetes | k3s (HA, embedded etcd), Traefik ingress, cert-manager, Argo CD, Sealed Secrets or External Secrets + SOPS |
| Edge | Cloudflare: DNS, proxy, WAF, Turnstile, Tunnel, R2, cache rules. Managed with Terraform (Cloudflare provider). |
| CI/CD | GitHub Actions → images in GitHub Container Registry → Argo CD (GitOps). Mobile builds with Fastlane (or Codemagic). |

---

## 5. Repository and code layout

### 5.1 Monorepo

```
3dmart/
├── apps/
│   ├── platform/          # the Laravel app: API, Inertia web (shop, supplier, admin), jobs, websockets
│   └── mobile/            # Flutter: flavors `shopper` and `staff`
├── packages/
│   └── aisle-engine/      # TypeScript + Three.js 3D aisle renderer, used by web and by the mobile WebView bundle
├── services/
│   └── mesh-builder/      # Node.js: parametric pack meshes, glTF optimization, thumbnails
├── workflows/
│   └── n8n/               # exported n8n workflows (JSON) + credentials templates (no secrets)
├── infra/
│   ├── terraform/         # Cloudflare (DNS, R2, WAF, Tunnel), optional Contabo provisioning
│   ├── ansible/           # node hardening, k3s install
│   ├── k8s/               # Helm values + Kustomize overlays: base, staging, production
│   └── argocd/            # Argo CD Application manifests
├── design/canvas/         # existing clickable design (reference only)
└── docs/
    ├── BRIEF.md
    ├── adr/
    └── runbooks/          # deploy, rollback, restore from backup, rotate secrets, incident
```

### 5.2 Laravel domain modules

Organize by domain under `app/Domain/<Module>`, each with Models, Actions, Data (DTOs), Events, Policies, Jobs. Keep HTTP (controllers, requests, resources) under `app/Http`, split by audience (`Api/V1/Shopper`, `Api/V1/Staff`, `Web/Shop`, `Web/Supplier`, `Web/Admin`). Add Pest architecture tests that stop modules reaching into each other's internals.

Modules:
- Identity
- Catalog
- Inventory
- Pricing & Promotions
- Planogram (3D store layout)
- Cart & Checkout
- Orders
- Payments
- Fulfilment (picking)
- Delivery (zones, slots, riders, tracking)
- Suppliers
- Retail Media
- Analytics (events)
- 3D Assets
- Notifications
- Compliance (consents, data requests, audit)
- Settings

### 5.3 API conventions

- REST, JSON, versioned under `/api/v1`. OpenAPI 3.1 spec generated from code (e.g., dedoc/scramble). Publish it in CI; the Flutter client is generated from it or checked against it.
- Auth: Sanctum bearer tokens for the apps, with one token per device and revocation on logout.
- Every write accepts an `Idempotency-Key` header. Store keys for 24h and replay the stored response.
- Errors follow RFC 9457 problem+json, with stable error codes that the apps translate.
- Pagination: cursor-based for feeds and lists.
- `Accept-Language: ar|en` picks the language of translatable fields and messages.
- Rate limits per route group: stricter on auth and OTP. Also protect those two with Cloudflare Turnstile on web and App Attest / Play Integrity on mobile (Phase 7).

---

## 6. Data layer: PostgreSQL 18

### 6.1 Principles

- Primary keys: UUIDv7 (`uuidv7()` is built into PostgreSQL 18). They sort by time and are safe to expose. Keep a short human order number separately (e.g., `#40218`).
- Money: `bigint` in piastres, with a `currency char(3)` column where more than one currency could ever appear.
- Timestamps: `timestamptz` everywhere.
- Translatable text: `jsonb` like `{"en": "...", "ar": "..."}` (spatie/laravel-translatable). Add generated columns for search (§6.4).
- Soft deletes only where there's a business reason (catalog, users). Never on money tables: those are append-only with reversing entries.
- Foreign keys and check constraints in the database, not only in the app.

### 6.2 PostgreSQL extensions: what we use and why

These are extensions to the PostgreSQL server. They must be in the database image (§10.5), not installed by hand.

| Extension | Use it for | Needed in |
|---|---|---|
| **postgis** | Delivery zones as polygons, "is this address deliverable?", nearest dark store, rider GPS positions, distance and ETA estimates, geofenced "rider arriving" notifications | Phase 2 |
| **pgvector** | Vector embeddings for: "replace with similar" substitutions, semantic search ("something for breakfast"), finding duplicate products when suppliers upload, matching supplier photos to existing SKUs. HNSW indexes. | Phase 3 (substitutions), Phase 6 (dedup) |
| **pg_trgm** | Typo-tolerant search on product names and brands in Arabic and English; fast `ILIKE` via GIN trigram indexes; admin search boxes | Phase 1 |
| **unaccent** | Normalizing Latin-script search terms (e.g., "creme" = "crème") | Phase 1 |
| **citext** | Case-insensitive unique columns: emails, promo codes, supplier slugs | Phase 1 |
| **btree_gist** | Exclusion constraints on time ranges: an ad placement can't be double-booked for overlapping dates; a rider can't have overlapping shifts; delivery-slot capacity windows | Phase 5 |
| **pg_stat_statements** | Finding slow and frequent queries. Feed Grafana dashboards. | Phase 0 |
| **pg_partman** | Time-partitioning of high-volume tables: `analytics_events`, `ad_events`, `rider_locations`, `audit_logs`. Monthly partitions, with automatic creation and retention. | Phase 3 |
| **pg_cron** | Database-side maintenance only: pg_partman's `run_maintenance_proc()` and concurrent refresh of reporting materialized views. Business scheduling stays in the Laravel scheduler, so there's one place to look. | Phase 3 |
| **pgaudit** | Session and object audit logging for compliance (who read or changed personal data at the database level). Log to stdout → Loki. | Phase 7 |

Considered and **not** used, so nobody adds them by accident:
- **uuid-ossp** and **pgcrypto** for UUIDs: `uuidv7()` and `gen_random_uuid()` are built in. Encrypt sensitive columns in the app with Laravel's encrypted casts.
- **TimescaleDB**: pg_partman plus materialized views covers our analytics volume without another licence to track.
- **pgmq** / Postgres-based queues: queues run on Redis with Horizon, as requested. Revisit only if Redis becomes a pain point.
- **hstore**: use `jsonb`.

Arabic search note: check which text-search configurations the chosen PostgreSQL build ships (`\dF`). If there's an `arabic` configuration, use it for Arabic `tsvector`s. Either way, normalize Arabic text in the app before indexing and searching:
- strip tashkeel (diacritics) and tatweel;
- unify alef forms (أ إ آ → ا);
- ta marbuta → ha;
- alef maqsura → ya.

Store the normalized text in generated or maintained columns. Test with real product names.

### 6.3 Core entities

Not exhaustive; Claude designs the full schema in Phase 0–1 and records it as an ADR with an ERD.

- **Identity:**
  - `users` (shoppers, staff and supplier users share one table, with roles);
  - `user_devices` (FCM tokens, platform, app version);
  - `addresses` (PostGIS point, text, notes, zone);
  - `consents`, `data_requests`.
- **Catalog:**
  - `brands`; `categories` (tree);
  - `products`: translatable name and description, brand, category, attributes as `jsonb`, physical dimensions in mm, weight, pack shape: `box | carton | can | jar | bottle | jug | bag | pouch | other`;
  - `product_variants`: SKU, GTIN/EAN barcode, size;
  - `product_media`: photos, with a role (front, back, left, right, top, bottom, lifestyle);
  - `product_embeddings` (vector).
- **Suppliers:**
  - `suppliers`, `supplier_users`;
  - `supplier_documents`: commercial register, tax card, food safety certificate; status and expiry;
  - `supplier_product_links`.
- **Locations and inventory:**
  - `locations` (dark stores; PostGIS);
  - `inventory_items` (location × variant: on hand, reserved, reorder point);
  - `stock_movements` (append-only ledger);
  - `replenishment_requests`.
- **Pricing and promotions:**
  - `prices` (variant × location, valid from/to);
  - `promotions`: type `percent | fixed | bxgy | bundle | code`, rules as `jsonb`, dates, stacking group, budget, owner (platform or supplier);
  - `promotion_targets`, `promo_codes`, `promotion_redemptions`.
- **Planogram (3D store):**
  - `stores_3d` (one per location);
  - `aisles`, `bays`, `shelves` (level, height);
  - `slots` (position, width);
  - `facings` (slot × variant, count, depth);
  - `planogram_versions`: draft → submitted → approved → **published**. The published version is an immutable JSON snapshot on R2 (§7.2).
- **3D assets:**
  - `model_jobs`: pipeline runs, tier (`standard | ai | artist`), status, provider cost, credits reserved/captured, logs link;
  - `model_credit_ledger`: append-only (purchase, grant, reserve, capture, release, refund, expiry) per supplier;
  - `credit_packs`: admin-defined packs and prices;
  - `artist_quotes`, `artist_assignments`;
  - `models_3d`: variant, GLB URLs per LOD, KTX2 texture set, bounding box, triangle count, status `draft | review | approved | rejected`.
- **Cart and checkout:**
  - `carts`, `cart_items`;
  - `checkouts`: frozen totals, substitution preference, slot, payment method.
- **Orders:**
  - `orders`: number, state, totals broken down (subtotal, discounts, delivery fee, VAT, total);
  - `order_items`: price snapshot, promotion snapshot;
  - `order_state_transitions`;
  - `substitutions`.
- **Payments:**
  - `payments`: provider, intent/reference, state, amount;
  - `payment_events`: raw webhooks, stored verbatim;
  - `refunds`;
  - `cod_collections`: rider, amount, reconciled-by.
- **Fulfilment and delivery:**
  - `pick_tasks`;
  - `delivery_zones` (PostGIS polygon, fee rules, min order);
  - `delivery_slots` (capacity);
  - `riders`, `shifts`;
  - `deliveries`;
  - `rider_locations` (partitioned).
- **Retail media:**
  - `ad_placements`: type `endcap | eye_level_facing | aisle_entrance_sign | sponsored_search`, location and aisle;
  - `ad_campaigns` (supplier, budget, daily cap, pricing model);
  - `ad_bookings`: placement × `tstzrange`, **exclusion constraint** (btree_gist);
  - `ad_creatives` (image or GLB, claims text, approval status);
  - `ad_events` (partitioned: impression, tap, add_to_cart, purchase).
- **Analytics:** `analytics_events`, partitioned. Generic event envelope: `name`, `user_id`, `session_id`, `device`, `props jsonb`, `occurred_at`.
- **Platform:** `notifications`, `audit_logs` (partitioned), `settings`, `idempotency_keys`, `webhook_calls` (inbound and outbound, with signature status).

### 6.4 Indexing and performance

- GIN trigram indexes on normalized product name columns (both languages) and brand names.
- GIN index on `tsvector` generated columns for full-text search.
- HNSW index on embeddings (cosine).
- GiST indexes on zone polygons and address/rider points.
- BRIN indexes on `occurred_at` in partitioned event tables.
- Materialized views for dashboards, e.g., `mv_supplier_daily_sales` and `mv_campaign_daily`, refreshed concurrently by pg_cron every 5–15 minutes.
- Connection pooling: CloudNativePG's PgBouncer `Pooler` in transaction mode for web pods. Octane keeps persistent connections, so size the pools deliberately (ADR).

---

## 7. The 3D store

### 7.1 Experience requirements

Build to the Version 2 prototype (`design/canvas/Aisle3D.dc.html`) and improve on it:

- **Walking and looking:** first-person walking along the aisle (hold-to-walk, swipe); drag to look; quick turns to face the left or right shelf; jump to a section.
- **The aisle itself:** real shelving, lighting, floor, signage in Arabic and English, shelf-edge price tags (offers highlighted), end-cap promo displays.
- **Tapping a pack:** it animates off the shelf into the shopper's hand. The shopper can rotate it and zoom in, see details and price, add to cart, or put it back.
- **Retail media:** placements render in the scene from the ad server, with impression and tap tracking.
- **Accessibility:** list view with identical content and actions; the screen reader uses the list view; reduced-motion setting.
- **Fallbacks:**
  - if the device can't sustain the frame rate (§7.4) or WebGL fails, switch to the list view automatically and tell the shopper;
  - the shopper can switch views at any time.

### 7.2 Data flow

1. Merchandisers (and suppliers, as proposals) edit the planogram in the web shelf planner.
2. An admin approves it and publishes a **planogram version**.
3. On publish, a job compiles a **store manifest** per aisle and writes it to R2 at `cdn.<domain>/stores/<store>/<version>/aisle-<n>.json`, cached immutably. The manifest holds:
   - geometry: bays, shelves and slots with coordinates;
   - facings, each with a product/variant ID and the model URL per LOD;
   - price tag data;
   - signage;
   - ad slots.
4. Prices and stock change more often than layout. They come from a separate small API call (`/api/v1/stores/{id}/aisles/{n}/live`), cached for 30–60 seconds, and are merged at runtime. Show out-of-stock facings as gaps, like a real shelf.
5. Models are GLB files with Meshopt compression and KTX2 (Basis) textures, in 2–3 LODs, served from R2 through the CDN with long cache lifetimes and content-hashed file names.

### 7.3 One 3D engine for web and mobile

**Default:** `packages/aisle-engine` is a TypeScript + Three.js library. It:
- takes a manifest, a live-data provider and callbacks (`onPickUp`, `onAddToCart`, `onImpression`, …);
- renders the aisle, using instancing per model and LOD, frustum culling per bay, and streaming bays in and out as the shopper walks.

It is used in two places:
- **Web:** a Vue component wraps it.
- **Mobile:** it's built into a static bundle shipped **inside the app** and shown in `webview_flutter`. It talks to Flutter over a typed JavaScript bridge (postMessage-style, versioned messages).

Why: one 3D codebase to maintain, and the prototype already proves the approach.

**Performance gate at the end of Phase 3 (Ask D3 only if it fails):** on the reference Android device (§7.4), the default aisle must hold ≥ 30 fps while walking, with first render ≤ 4 s on 4G. If it can't, evaluate embedding Unity via a Flutter plugin, using the same manifest format, and write an ADR comparing the two with measured numbers.

### 7.4 Performance budgets

| Metric | Budget |
|---|---|
| Reference devices | Low: a mid-range Android with 4 GB RAM (e.g., a Samsung Galaxy A-series from the last two years); high: a recent iPhone. **Ask D4** for the client's exact target devices. |
| Frame rate | ≥ 30 fps on the low device, 60 fps on the high device and desktop |
| First aisle render | ≤ 4 s on 4G for the first bay, the rest streamed |
| Download per aisle | ≤ 15 MB compressed at the default LOD |
| Draw calls | ≤ 300 per frame |
| Per-pack model | ≤ 5k triangles at LOD0, ≤ 500 at LOD2, textures ≤ 1024² (KTX2) |
| Memory | Stays inside WebView limits on the low device; unload bays behind the shopper |

---

## 8. Commerce details

### 8.1 Cart, pricing and promotions

- The server is the only authority on prices and totals. Clients show server-calculated totals.
- The promotion engine evaluates eligible promotions in a set order:
  1. item-level;
  2. multibuy / BxGy;
  3. bundles;
  4. basket-level;
  5. codes.

  It follows stacking groups and records applied promotions on the order (snapshot).
- Promotions have budgets and caps (per user and in total), schedules, and an owner (platform or supplier-funded, which matters for settlement).
- Delivery fee rules are per zone:
  - a minimum order value (EGP 100 in the design);
  - a free-delivery threshold (EGP 300 in the design).

  Make both configurable.

### 8.2 Checkout and payments

**Payment flows:**
- **Paymob (card, Meeza, wallet):** create a payment intention server-side; the app opens Paymob's hosted/SDK flow; confirmation comes **only** from the verified webhook (HMAC), never from the client.
- **Fawry:** create a reference code with an expiry (default 24h), shown to the shopper; the order stays `awaiting_payment`. On the Fawry notification (signature verified), move it to `paid`. On expiry, cancel and release reserved stock.
- **COD:** the order is confirmed immediately. The rider app records collection. Finance reconciles cash per rider shift.

**Rules for every payment flow:**
- Store every inbound webhook verbatim in `payment_events` before processing.
- Process on the `payments` queue with idempotency on the provider reference.
- Refunds: full and partial, through the provider API, with an admin approval threshold.
- **Ask (D5):** merchant accounts and credentials for Paymob and Fawry. Build against their sandboxes behind a `PaymentGateway` interface, with a fake gateway for tests.

### 8.3 Order lifecycle

```
draft → awaiting_payment → confirmed → picking → packed → out_for_delivery → delivered
                  │              │           │                     │
                  └→ cancelled   └→ cancelled└→ partially_substituted (still flows to packed)
                                                                    └→ failed_delivery → returned → refunded
```

- Every transition is explicit, authorized, logged in `order_state_transitions`, and fires events that drive:
  - notifications (push, SMS);
  - websocket updates;
  - supplier "order received" alerts;
  - analytics.
- Stock:
  - **reserve** at checkout confirmation;
  - **commit** at packing;
  - **release** on cancellation or expiry.
- Substitution preference per order: replace with similar (pgvector suggestions, picker confirms), call me, or remove.

### 8.4 Delivery

- Zones are PostGIS polygons drawn in the admin portal on a map; each has a fee, a minimum order, and slot capacity.
- Slots: express (as soon as possible, estimated from rider availability and distance) and scheduled (capacity-limited windows).
- Live tracking:
  - the rider app sends its location every 5–10 s while on a job (battery-aware);
  - the server stores positions in the partitioned `rider_locations` table and broadcasts them over Reverb on a private channel `order.{id}`;
  - the shopper app shows the rider on a Google Map with an ETA.
- Rider assignment: manual in the admin portal for MVP (as designed), with an "auto-assign nearest available rider" button behind a feature flag.

### 8.5 Notifications

Channels:
- push (FCM for Android; APNs through FCM for iOS);
- SMS (codes, and critical order updates when push isn't delivered);
- email (receipts, supplier notices);
- in-app inbox.

Write templates in Arabic and English. Put a `Notifier` abstraction in front of providers. **Ask (D6):** SMS provider (a local Egyptian gateway or an international verify service). Build a driver interface plus a log driver for development.

---

## 9. Photo → 3D pipeline (n8n)

### 9.1 Goal and tiers

A supplier uploads real photos of a pack. The platform produces a correctly sized, optimized 3D model that looks like the real pack. A person approves it, and it goes on the shelves.

There are three tiers. Only the first is free.

| Tier | Who pays | What it does | Uses AI? |
|---|---|---|---|
| **Standard** (included) | Free for every supplier | Classic image processing + parametric pack shapes (§9.4). Covers boxes, cartons, cans, jars, bottles, jugs, bags and pouches shot to the photo standard (§9.3). | No |
| **AI conversion** (paid add-on) | Supplier, per model | Everything in Standard, plus AI steps that cope with messy photos (busy backgrounds, angled shots), read label text automatically, and build models for irregular shapes (§9.5). | Yes |
| **Artist modelling** (paid add-on) | Supplier, per model, quoted | A 3D artist models the product by hand in Blender from the supplier's photos (§9.6). For hero products, odd shapes, or anything the other tiers can't do well. | No |

**Default:** the Standard tier is the default everywhere. The AI tier is built behind a feature flag (Laravel Pennant, `ai-3d-conversion`) and switched on only once D7 is settled.

### 9.2 Paying for add-ons

- **Model credits.** Suppliers buy credit packs in the supplier portal.
  - An AI conversion costs a set number of credits.
  - Artist modelling is quoted per product by an admin, then accepted by the supplier and paid in credits or on invoice.
  - Prices are admin settings, not code. **Ask (D15)** for prices; use `[EGP per credit]` placeholders until then.
- **Buying credits:**
  - by card or wallet through Paymob (the same `PaymentGateway` as shopper payments, with a separate merchant integration if Paymob requires one);
  - or granted by a finance admin against a bank transfer or invoice.

  Either way, every change goes through an append-only `model_credit_ledger`: purchase, grant, reserve, capture, release, refund, expiry. The balance is the sum of the ledger, never a mutable number.
- **Charging rules** (fair and predictable for suppliers):
  1. **Reserve** credits when an AI job starts.
  2. **Capture** them only when the job delivers a model that passes the automatic checks.
  3. **Release** them if the pipeline fails or times out.
  4. **One free retry** if the supplier rejects the result for quality.
  5. Artist jobs are captured on the supplier's acceptance of the finished model.
- **Upsell moments in the portal:**
  - when a Standard job fails its checks, offer AI conversion or artist modelling for that product, showing the price;
  - when the supplier picks shape `other`, explain that Standard can't build it and show the two paid options.
- **Cost tracking:** record each job's actual provider cost (GPU time or API fee) next to what the supplier paid, and show the margin in the admin finance area.
- **Invoicing:** credit purchases produce invoices through the same `InvoiceIssuer` interface as orders (§1.7).

### 9.3 Photo standard (makes Standard reliable)

Show this as a guided upload screen with example photos. It's also a printable one-page guide suppliers can give their photographer.

- **Backdrop:** plain white (or chroma green) sweep or a cheap lightbox, even light, no hard shadows.
- **Colour:** a small grey or colour reference card in one extra shot, used for white balance.
- **Camera:** phone camera is fine; fixed distance; the pack fills most of the frame; short side ≥ 1500 px.
- **Boxes, cartons, bags, pouches:** front, back, left, right, top, bottom, each shot straight on.
- **Cans, jars, bottles, jugs:** front and back, plus **a 10–20 second video on a turntable** (a cheap manual turntable is enough) for the wrap-around label.
- **Transparent packs** (water, oil): shoot with the product inside, against white. The body colour and transparency come from the shape settings, not the photo.

The upload screen checks basic quality right away:
- resolution;
- blur (variance of the Laplacian);
- over-exposure;
- whether the background is plain enough.

It then tells the supplier what to reshoot before anything is queued.

### 9.4 Standard pipeline (no AI)

Runs entirely on our cluster, on CPU; no GPU and no external model.

**Inputs:**
- photos and video;
- physical dimensions in mm (required);
- pack shape, chosen by the supplier from a list with pictures;
- name, brand and size, typed or confirmed by the supplier (they already enter these in the catalog).

Uploads go **directly to R2** with presigned PUT URLs (the private bucket). They never pass through Laravel or Cloudflare's request-size limits.

**Steps** in `services/mesh-builder`. Add a Python worker alongside it for the OpenCV work if that's cleaner, and record the choice in an ADR.

1. **Background removal:**
   - colour-threshold against the plain backdrop, in HSV or Lab colour space;
   - morphological clean-up;
   - keep the largest contour;
   - optional GrabCut refinement on the edge band.
2. **Straighten flat faces:**
   - find the face's four corners (contour → polygon approximation);
   - apply a perspective (homography) warp to a rectangle with the exact aspect ratio of the declared dimensions.
3. **Unwrap cylinders** from the turntable video:
   - take one frame every few degrees;
   - cut a thin vertical strip from the centre of each;
   - blend them into one wrap-around label (a strip-scan panorama);
   - match its width to the circumference from the declared diameter.
4. **Colour:** white-balance from the backdrop or reference card; mild denoise and sharpen.
5. **Build the mesh:** the parametric shape for the chosen type and exact dimensions. The prototype's geometry is the starting point:
   - gable-top cartons;
   - puffed bags with crimped seals;
   - lathe-profile bottles and jugs;
   - cans with lids;
   - jars.

   Map the textures onto the matching faces; the cylinder wrap goes around the body.
6. **Optimize** (glTF-Transform):
   - pivot at the base centre, front facing +Z (the engine's convention);
   - LOD0/1/2;
   - Meshopt compression;
   - KTX2 textures;
   - a transparent PNG thumbnail and a 360° turntable preview.
7. **Automatic checks:**
   - bounding box within ±3% of the declared dimensions;
   - triangle and texture budgets (§7.4);
   - no missing faces or textures;
   - front texture compared with the front photo by colour histogram and a structural-similarity (SSIM) score.
8. **Result:**
   - upload to R2 (public bucket, content-hashed paths);
   - Laravel sets the model to `review`;
   - a person approves or rejects it in the portal's 3D viewer. That review also covers what an AI would have caught: wrong side, blurry label, wrong product.

**If a Standard job fails its checks,** the supplier sees exactly why, e.g., "background not plain enough on the left photo", "front face corners not found". They can reshoot for free, or buy AI conversion or artist modelling (§9.2).

### 9.5 AI conversion (paid, optional)

Only runs when the flag is on, the supplier has enough credits, and they chose it.

It reuses the Standard steps and swaps in AI where Standard is weak:

- **Background removal** with a segmentation model (e.g., BiRefNet or rembg), so busy backgrounds work.
- **Pack understanding:** a vision-capable Claude model (Anthropic API) that:
  - suggests the shape;
  - reads the brand, product name and size in Arabic and English, pre-filling catalog fields for the supplier to confirm;
  - flags photo problems.
- **Irregular shapes** (shape `other`, or when Standard fails): an image-to-3D model on a rented GPU endpoint, since the Contabo nodes have no GPUs. Candidates (**Ask D7**; check each licence for commercial use in Egypt):
  - Microsoft TRELLIS (MIT licence);
  - Tencent Hunyuan3D 2.x (community licence with territory restrictions);
  - Stability AI Stable Fast 3D (Stability Community Licence, with a revenue threshold);
  - a commercial API such as Meshy, Tripo or Rodin.

  Put all of them behind an `ImageTo3D` interface so the provider can be swapped.
- **Also offered for irregular shapes: photogrammetry** (COLMAP + OpenMVS, or Meshroom). It's classic computer vision rather than AI, but it's expensive to run, so it sits in the paid tier.
  - It needs 30–80 photos taken around the object.
  - It struggles with shiny, transparent or plain single-colour surfaces.
  - Dense reconstruction is only practical on a GPU.

  Choose between photogrammetry and image-to-3D per job, based on the photos provided.

The output goes through the same optimize → checks → review steps as Standard.

### 9.6 Artist modelling (paid)

- The supplier requests it for a product; an admin sends a quote; the supplier accepts in the portal; credits are reserved.
- The job appears in an admin "Artist queue", where artists download the photos and dimensions, then upload the finished GLB or `.blend` file.
- Uploads go through the same optimize and automatic checks, then supplier review. Two revision rounds are included.
- Artists can be staff or freelancers with an `artist` role that only sees assigned jobs.

### 9.7 The n8n workflows

Export all of these to `workflows/n8n/`.

- **`product-photo-to-3d-standard`:**
  1. HMAC-verified webhook from Laravel with `{job_id, variant_id, tier, photos: [{role, presigned_get_url}], video_url?, dims_mm, shape, callback_url}`.
  2. Validate.
  3. Call `mesh-builder` to clean up the images.
  4. Call `mesh-builder` to build the mesh, then optimize it.
  5. Run the checks.
  6. Upload to R2.
  7. Send an HMAC-signed callback: status, file URLs, metrics, warnings.
- **`product-photo-to-3d-ai`:** same shape, with AI nodes in place of or in addition to the Standard steps. It records the provider cost in the callback so Laravel can capture or release credits.
- **`artist-job-notify`:** notifies artists and admins on quote, acceptance, delivery and revisions.

**How they run:**
- Retries with backoff on every external step.
- A dead-letter path reports failures back to Laravel, which releases any reserved credits.
- Per-supplier concurrency limits.
- A dashboard of job counts, durations and cost.
- Credentials live in Kubernetes secrets, never in the exported JSON.

### 9.8 n8n deployment

- Queue mode: `main` (editor, restricted to admins behind Cloudflare Access), `webhook` pods, and `worker` pods.
- Its own database on the Postgres cluster, and Redis for its queue.
- n8n is under the Sustainable Use License, which allows internal business use like this. Note it in an ADR.

---

## 10. Infrastructure

### 10.1 Cluster on Contabo

Starting size; tune after load tests:
- **3 control-plane nodes** (k3s servers, embedded etcd, HA): about 4 vCPU / 8 GB each. Tainted, so app pods don't run there.
- **3+ app worker nodes:** about 8 vCPU / 24–32 GB each, for Laravel, Horizon, Reverb, n8n and mesh-builder.
- **3 database nodes** with NVMe storage, labelled and tainted for PostgreSQL (one CloudNativePG instance each) and Redis.
- All nodes in the same Contabo region. **Ask (D8):** region choice. Pick the lowest latency to Cairo that Contabo offers, and measure it.

**Networking:**
- Use Contabo's private networking between nodes if it's available in the region.
- Encrypt node-to-node traffic anyway (k3s flannel `wireguard-native` backend, or Cilium with WireGuard).
- Firewall: allow only SSH (from an admin allowlist or a VPN) and the Kubernetes and WireGuard ports between nodes. **No public HTTP ports**: web traffic comes in through Cloudflare Tunnel.

**Provisioning:**
- Ansible playbooks to harden nodes: SSH keys only, unattended security upgrades, fail2ban, time sync.
- Ansible also installs k3s.
- Keep node definitions in code. Use Contabo's API or Terraform provider where practical.

### 10.2 Load balancing and ingress

Contabo has no managed cloud load balancer, so:

1. **Cloudflare proxy** terminates TLS for the public hostnames and applies WAF, rate limiting and caching.
2. **Cloudflare Tunnel:** a `cloudflared` Deployment with 2–3 replicas spread across worker nodes. Each replica keeps outbound connections to Cloudflare, which balances requests across healthy replicas. No inbound ports are open, and the origin IPs stay hidden.
3. `cloudflared` forwards to **Traefik** (ingress controller, several replicas), which routes by host and path to Kubernetes Services. Services load-balance across pods.
4. Horizontal Pod Autoscalers on `web` (CPU and requests), `horizon` (queue length via a Prometheus adapter or KEDA) and `reverb` (connections).

Websockets (Reverb) work through Tunnel. Set timeouts and keepalives accordingly, and test long connections.

If Tunnel ever becomes the bottleneck, the documented alternative is:
- proxied DNS records pointing at several nodes' public IPs;
- Traefik exposed on those nodes;
- Cloudflare Load Balancing with health checks.

Write both options into the ADR.

### 10.3 Cloudflare

Manage all of this with Terraform in `infra/terraform/cloudflare`:

- **DNS:** `app.` (web shop), `api.`, `supplier.`, `admin.`, `ws.` (Reverb), `cdn.` (R2 public bucket), `n8n.` (behind Cloudflare Access).
- **TLS:** Full (strict) between Cloudflare and origin, using a Cloudflare Origin CA certificate or cert-manager with the DNS-01 challenge through the Cloudflare API.
- **WAF:**
  - managed rules;
  - rate-limit rules on `/api/v1/auth/*`, OTP and checkout;
  - bot protection;
  - **Turnstile** on web sign-in, OTP request and sign-up.
- **Cloudflare Access (zero trust)** in front of `admin.`, `n8n.`, Grafana and Argo CD, on top of the app's own login and 2FA.
- **Cache rules:**
  - long, immutable caching for `cdn.` content-hashed assets (GLB, KTX2, images, manifests);
  - bypass for API and Inertia HTML.
- **R2 buckets:**
  - `3dmart-public`: product images, 3D models, store manifests, ad creatives. Served on `cdn.` via a custom domain, with CORS for the web shop origin.
  - `3dmart-private`: raw supplier photos, supplier documents, invoices, data exports. Access only through short-lived presigned URLs generated by Laravel.
  - `3dmart-backups`: database backups. Separate API token with write access only from the backup job; lifecycle rules for retention.
- **Laravel config:** `s3` driver with `endpoint=https://<account_id>.r2.cloudflarestorage.com`, `region=auto`. One disk per bucket.
- **Image variants** (thumbnails, WebP/AVIF) are generated on the queue by medialibrary conversions. Cloudflare Image Transformations is an optional later optimization.

### 10.4 Kubernetes workloads

| Workload | Kind | Notes |
|---|---|---|
| `platform-web` | Deployment + HPA | Octane/FrankenPHP; readiness `/up`; min 3 replicas across nodes (pod anti-affinity) |
| `platform-horizon` | Deployment + HPA/KEDA | Queues: `payments` (highest priority), `default`, `notifications`, `media`, `models3d`, `analytics`, `webhooks` |
| `platform-reverb` | Deployment ×2+ | Scales over Redis pub/sub |
| `platform-scheduler` | Deployment ×1 | Runs `schedule:work`; use `onOneServer()` for jobs anyway |
| `platform-migrate` | Job (Argo CD PreSync hook) | `php artisan migrate --force`; migrations must be backward compatible for one release (expand/contract) |
| `n8n-main`, `n8n-webhook`, `n8n-worker` | Deployments | Queue mode |
| `mesh-builder` | Deployment + HPA | CPU-heavy; resource limits; internal only |
| `cloudflared` | Deployment ×2–3 | Tunnel connectors |
| `traefik` | Helm chart | k3s default or chart-managed |
| `postgres` | CloudNativePG `Cluster` ×3 | Custom image with the extensions from §6.2; PgBouncer `Pooler` |
| `redis` | StatefulSet (primary + replica + Sentinel), or an operator | AOF persistence; separate logical databases or key prefixes for cache, queues and Reverb; `maxmemory` policy set per use |
| monitoring | kube-prometheus-stack, Loki + Promtail/Alloy, Grafana, Alertmanager | Alerts to email / Slack / WhatsApp |
| GitOps | Argo CD | App-of-apps; staging auto-sync, production manual sync |
| secrets | Sealed Secrets or External Secrets + SOPS | No plaintext secrets in git |

- Namespaces: `platform`, `data`, `workflows`, `edge`, `monitoring`, `argocd`.
- Staging runs in the same cluster under `*-staging` namespaces, with its own database cluster and R2 buckets. Production and staging never share credentials.
- Every Deployment has requests and limits, liveness and readiness probes, a PodDisruptionBudget, and topology spread across nodes.

### 10.5 PostgreSQL image, backups and disaster recovery

- Build a custom CloudNativePG-compatible PostgreSQL 18 image in CI, starting from the official CloudNativePG PostGIS image and adding pgvector, pg_partman, pg_cron and pgaudit.
- Set `shared_preload_libraries` for `pg_stat_statements`, `pg_cron` and `pgaudit`. Create the extensions with a migration that runs `CREATE EXTENSION IF NOT EXISTS` (as the owner role).
- Test the image in CI by running the full test suite against it.
- Local development and CI use the same image.
- **Backups:**
  - CloudNativePG continuous WAL archiving plus daily base backups to the R2 backups bucket (S3-compatible; verify compatibility in Phase 0 and record it);
  - retention: 30 days;
  - point-in-time recovery.
- **Targets:** RPO ≤ 5 minutes, RTO ≤ 1 hour.
- **Monthly restore drill** into a scratch namespace, scripted and documented in `docs/runbooks/restore.md`.
- Redis holds no system-of-record data. Losing it loses in-flight queue jobs only; money-related jobs must be safe to re-run from database state.

### 10.6 CI/CD

GitHub Actions on every PR:
- **PHP:** Pint, Larastan, Pest in parallel against the custom Postgres image and Redis service containers, plus architecture tests.
- **JS/TS:** ESLint, Prettier, `vue-tsc`, unit tests (Vitest), and aisle-engine tests (headless WebGL smoke test).
- **Flutter:** `flutter analyze`, unit and widget tests, a golden test for key screens in Arabic RTL and English.
- **Checks:** OpenAPI spec diff (breaking changes fail unless labelled); security scanning with `composer audit`, `npm audit`, Trivy on images and gitleaks.

On merge to `main`:
- build and push images to GHCR, tagged with the git SHA;
- Argo CD auto-syncs **staging**;
- production is promoted by a PR that bumps the image tag in `infra/k8s/overlays/production`.

Mobile releases:
- Fastlane lanes build signed Android App Bundle and iOS builds;
- upload to Play internal testing and TestFlight;
- store submission is manual.

**Ask (D9):** Apple Developer and Google Play accounts.

### 10.7 Observability

- **Metrics:** app metrics exported to Prometheus (HTTP latency, queue depth and wait time, job failures, websocket connections, payment success rate), plus Postgres metrics (CloudNativePG exporter, pg_stat_statements) and Redis metrics.
- **Logs:** structured JSON logs → Loki, with a request ID propagated from Cloudflare (`cf-ray`) through Laravel to jobs.
- **Errors:** Sentry for Laravel, Vue and Flutter, with release tracking.
- **Alerts:**
  - API 5xx rate;
  - p95 latency;
  - queue wait over 60 s on `payments`;
  - failed-payment spike;
  - replication lag;
  - backup failure;
  - disk space;
  - certificate expiry;
  - Tunnel connectors down.

---

## 11. Security

- Authentication:
  - Shoppers: phone number + SMS code (6 digits, 5-minute expiry, rate-limited, Turnstile on web, device attestation on mobile), or Google/Apple.
  - Staff and supplier users: email + password + **mandatory 2FA** (TOTP).
  - Admin portal: behind Cloudflare Access as well.
- RBAC with least privilege. Suppliers only ever see their own data: enforce with policies **and** query scopes, with tests per endpoint for cross-tenant access.
- **Webhooks:**
  - inbound (Paymob, Fawry, n8n): verify signatures, check timestamps against replay, deduplicate by provider ID;
  - outbound: HMAC-signed.
- File uploads:
  - presigned uploads with content-type and size limits;
  - server-side validation after upload (magic bytes);
  - images re-encoded;
  - documents never served from the public bucket.
- **Headers:** Content Security Policy, HSTS (via Cloudflare), secure cookies, CSRF on web, CORS limited to known origins.
- **Secrets:** stored in Sealed Secrets / External Secrets and rotated per runbook. The app never logs tokens, codes or card data. No card data ever touches our servers: the Paymob hosted flow keeps us out of PCI scope, so record that in an ADR.
- Dependency updates with Renovate or Dependabot, grouped weekly.
- Before launch: an external penetration test or, at minimum, a structured OWASP ASVS level 2 self-review.

---

## 12. Mobile apps (Flutter)

- One codebase, two **flavors**:
  - `shopper`: 3D Mart;
  - `staff`: 3D Mart Staff, with picker and rider modes chosen by role.
- Structure: feature-first folders; Riverpod for state; go_router with deep links (`3dmart://product/{id}`, universal / app links for order tracking); dio with interceptors (auth, `Accept-Language`, idempotency keys, retry); freezed models generated from or checked against OpenAPI.
- **Arabic and RTL:** `Directionality` from locale; only directional paddings and alignments (`EdgeInsetsDirectional`, `AlignmentDirectional`); mirrored icons where meaningful; Western digits by default, with a setting for Arabic-Indic digits. **Ask (D10):** confirm the digit preference.
- **3D:**
  - the aisle-engine bundle is shipped in the app's assets and loaded in a WebView from local files;
  - models and manifests are fetched from `cdn.` and cached with an LRU disk cache (size cap);
  - the typed JS bridge (§7.3) connects the two sides;
  - frame-rate telemetry is reported back, triggering the automatic fallback to the list view.
- **Offline behaviour:** cached catalog and cart are browsable offline, with a clear banner; checkout needs a connection.
- **Payments:** Paymob's mobile SDK or hosted page in a secure in-app browser. Return to the app by deep link; confirmation still comes from the server.
- **Maps:** Google Maps for address pins and tracking. **Ask (D11):** Google Maps Platform billing account.
- **Firebase:** Messaging (push), Crashlytics or Sentry (pick one: Sentry is the default, to match the backend), and Analytics for app funnels. Product and ad events go to our own API, because retail media reporting must come from our data.
- **Staff app:**
  - pick lists sorted by aisle and shelf position (from the planogram);
  - barcode scanning to confirm picks;
  - substitution flow with shopper notification;
  - rider job list, navigation hand-off to Google Maps, proof of delivery (photo and/or code), COD collection;
  - background location only while on a job, with the OS-required disclosures.

---

## 13. Web apps (Laravel + Inertia + Vue)

Three areas in the same app, each with its own layout, navigation and route prefix / subdomain:

- **Shop** (`app.`): home, 3D aisle (aisle-engine Vue wrapper), list view, search, product page, cart, checkout, orders and tracking, account. Server-side rendering with Inertia SSR for public catalog pages (SEO); the 3D view is client-only.
- **Supplier portal** (`supplier.`): build every screen in the Version 1 supplier board:
  - overview with charts;
  - orders received;
  - inventory and prices;
  - promotions;
  - shelf planner, which proposes changes that go to admin approval;
  - retail media: bookings, creatives, campaign results;
  - 3D models: guided photo upload with instant quality feedback, job status, review in the 3D viewer;
  - model credits: balance, buy packs (Paymob), history, invoices; choose AI conversion or request an artist quote per product;
  - team and permissions;
  - documents.
- **Admin portal** (`admin.`): everything in the Version 1 admin board, plus:
  - catalog;
  - planogram editor, with drag-and-drop slots and a live 3D preview using aisle-engine;
  - delivery zones (map polygon editor) and slots;
  - promotions;
  - payments, refunds and COD reconciliation;
  - supplier settlements;
  - users and roles;
  - settings;
  - audit log;
  - data requests.

Shared requirements:
- Arabic and English with RTL across all three areas.
- Accessible components (keyboard, focus, contrast AA), following the canvas's design tokens.
- Charts follow the dashboard conventions in the design (one axis, single-hue series, hover tooltips, table view).

---

## 14. Delivery phases

Each phase ends with its acceptance criteria met, CI green, deployed to staging, and a short demo note in `docs/demos/phase-N.md`.

| Phase | Deliverables | Acceptance criteria |
|---|---|---|
| **0: Foundations** | Monorepo; Laravel app with the Vue starter kit; Flutter app with both flavors; aisle-engine package skeleton; custom Postgres image with all §6.2 extensions; local dev via Docker Compose; CI pipelines; Terraform for Cloudflare (DNS, R2, Tunnel); Ansible + k3s cluster; Argo CD; staging deployed; monitoring; backups to R2 with one restore tested; ADR-0001…0005 | `https://api.staging…/up` is green through Cloudflare Tunnel; `CREATE EXTENSION` for every §6.2 extension succeeds in CI and on the cluster; a restore drill has been done; staging redeploys automatically from `main` |
| **1: Identity & catalog** | Auth (codes, social, 2FA for staff), roles; catalog, brands, categories, variants, media on R2; search (pg_trgm + full-text + Arabic normalization); admin catalog screens; supplier onboarding and document approval | Shopper can sign in on mobile and web; admin can create products with photos; search finds products with typos in both languages (test suite of 100+ real query/expectation pairs) |
| **2: Commerce core** | Locations, inventory ledger, prices; delivery zones (PostGIS) and slots; cart, checkout, promotions engine v1 (percent, fixed, code); orders with state machine; COD end to end; list-view shopping in the app and web | A shopper in a covered zone can place a COD order from the list view, and an admin sees it live; addresses outside zones are rejected; stock reserves and releases correctly (property tests) |
| **3: 3D store** | Planogram model and editor; publish → manifests on R2; aisle-engine (walking, look, pick-up, put back, add to cart, price tags, signage); WebView integration; analytics events (partitioned) | The performance gate in §7.3 passes on the reference devices, with numbers recorded in an ADR; an item added in 3D shows in the cart with the correct server price; the automatic list-view fallback works |
| **4: Payments & delivery** | Paymob and Fawry (sandbox → production), refunds; staff app (picking with barcode scan, rider jobs, COD collection); live tracking over Reverb; notifications (push, SMS, email) | All three payment methods succeed and fail correctly in sandbox, including duplicate and out-of-order webhooks; a rider's position updates on the shopper's map within 10 s; COD reconciliation balances in a test shift |
| **5: Suppliers & retail media** | Supplier portal complete; promotions v2 (BxGy, bundle, supplier-funded); retail media: placements, bookings (exclusion constraints), creatives, approvals, in-scene rendering, event tracking, attribution, reporting | Two suppliers can't see each other's data (automated tests on every supplier endpoint); overlapping bookings are rejected by the database; campaign report numbers match raw events |
| **6: Photo → 3D** | Photo standard and guided upload with instant checks; mesh-builder Standard tier (OpenCV clean-up, face straightening, cylinder unwrap, parametric meshes, optimize, thumbnails); n8n Standard workflow; review UI; model credits (ledger, packs, Paymob purchase, admin grants, invoices); artist queue and quotes; AI tier behind the `ai-3d-conversion` flag with the `ImageTo3D` interface and one provider | 20 real packs across all standard shapes, shot to the photo standard, go from photos to approved models with **no AI**; ≥ 90% pass automatic checks first time; credits reserve, capture and release correctly in every path, including failures and the free retry (tests); an artist job runs end to end; median processing time recorded |
| **7: Hardening & launch** | Load tests (k6) at 3× expected peak; security review and fixes; pgaudit; data export and deletion flows; e-receipt hook (D2); runbooks; store listings | Load test meets the §15 targets; no high or critical findings open; restore drill passes; apps approved in both stores |

---

## 15. Non-functional requirements

| Area | Target |
|---|---|
| Availability | 99.9% monthly for API and web |
| API latency | p95 ≤ 300 ms, p99 ≤ 800 ms for read endpoints under expected peak |
| Expected peak (initial) | **Ask (D12).** Default planning figure: 50k monthly active shoppers, 2k concurrent sessions, 50 orders per minute at peak. Load-test at 3× this. |
| Backups | RPO ≤ 5 min, RTO ≤ 1 h, monthly restore drill |
| Security | OWASP ASVS L2; no card data stored; admin actions audited |
| Accessibility | WCAG 2.2 AA for web; platform accessibility guidelines for mobile; full list-view alternative to 3D |
| Localization | 100% of UI strings in Arabic and English; RTL layout verified by golden tests |
| Test coverage | ≥ 80% lines in domain modules; every money path and state transition covered by feature tests |

---

## 16. Decisions for the product owner

Build to the defaults until these are answered.

| ID | Question | Default |
|---|---|---|
| D1 | Operating model: dark stores, partner supermarkets, or supplier fulfilment? | Dark-store model; inventory per location |
| D2 | VAT and e-receipt obligations and timing | `InvoiceIssuer` interface with a no-op implementation; VAT fields on orders |
| D3 | Unity instead of a WebView + Three.js if the performance gate fails | Three.js in a WebView |
| D4 | Target reference devices | A mid-range 4 GB Android + a recent iPhone |
| D5 | Paymob and Fawry merchant accounts | Build against sandboxes |
| D6 | SMS provider | Driver interface + log driver |
| D7 | AI tier: which image-to-3D / photogrammetry / segmentation providers, and licence approval | Standard (no AI) tier only; AI tier built behind a feature flag with the provider interface |
| D8 | Contabo region and node plan | Lowest latency to Cairo, as in §10.1 |
| D9 | App store accounts and app names | Placeholders: "3D Mart" and "3D Mart Staff" |
| D10 | Arabic digit style | Western digits, with a setting |
| D11 | Google Maps Platform account | Required by Phase 2 |
| D12 | Traffic expectations for launch | As in §15 |
| D13 | Brand usage: written permission from brands shown in the 3D store and marketing | Only suppliers who have signed up appear in production; demo data uses clearly fictional brands |
| D14 | Domain name | `3dmart.example` placeholder in config and Terraform variables |
| D15 | Prices for model credits, AI conversion and artist modelling; whether credits expire | Admin-configurable, placeholder `[EGP per credit]`; credits don't expire |

---

## 17. Definition of done (every piece of work)

- Code follows the layout in §5; Pint, Larastan, ESLint and `flutter analyze` are clean.
- Tests are written, and they fail without the change.
- Arabic and English strings are both added; RTL is checked.
- Migrations are reversible, or documented as expand/contract.
- New environment variables are documented in `.env.example` and the Helm values, and are **not** committed with real values.
- Observability: new endpoints and jobs have metrics and logs; new failure modes have alerts where it matters.
- There's an ADR when a decision was made; the relevant runbook is updated when operations change.
- Deployed to staging and checked there.

# 3D Mart

Concept work for a 3D interactive FMCG shopping app: shoppers walk a virtual supermarket aisle, pick products off the shelf and check out, while suppliers manage stock, shelf placement, promotions and in-store ads.

Build brief for the full platform (business goals, architecture, data model, infra, phases): [`docs/BRIEF.md`](docs/BRIEF.md).

Agent team for the build (Opus 5.5 as lead, 17 subagents with assigned models): [`docs/AGENTS.md`](docs/AGENTS.md), definitions in `.claude/agents/`.

Live, clickable design canvas: https://claude.ai/artifact/TVAA4Zu3sAkqNyyyxDVDvr (private until shared).

## What's in `design/canvas`

These are the source files of the design canvas. Each `*.dc.html` file is one artboard; `canvas.json` holds the layout, pages and board titles.

**Version 1**

| File | Board |
|---|---|
| `Main.dc.html` | Shopper app (phone): login with OTP, 3D aisle, list view, search, cart, checkout (Paymob, Fawry, cash on delivery), order tracking. English and Arabic (RTL). |
| `Arabic.dc.html` | The shopper app opened in Arabic |
| `Lite.dc.html` | The shopper app opened in list view, for low-end phones |
| `Supplier.dc.html` | Supplier dashboard: overview, orders, inventory and prices, promotions, shelf planner, retail media |
| `Admin.dc.html` | Platform admin: live orders, supplier approvals, ad approvals, riders and pickers |
| `Proposal.dc.html` | Proposed architecture, roadmap and cost placeholders for the RFP response |

**Version 2**

| File | Board |
|---|---|
| `Aisle3D.dc.html` | Realistic walk-through aisle built with Three.js (r149): shelving, lighting, Egyptian brands as 3D packs, pick-up and inspect, add to cart |

## Notes

- The boards use the canvas's own runtime (`support.js`, `DCLogic`), so they render inside the design canvas rather than as standalone pages.
- `Aisle3D.dc.html` loads `three.min.js` (three@0.149.0) from the canvas's asset store via a `/_blob/…` URL.
- Brand names are used for demonstration only; pack artwork is an approximation, not the brands' real packaging. Prices and dashboard figures are sample data.

## Planned stack

Flutter (iOS and Android) with a Unity module for the 3D store, a Laravel REST API, and Laravel + Inertia.js + Vue 3 for the supplier and admin dashboards, hosted on AWS.

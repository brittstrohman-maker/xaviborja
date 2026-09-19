# Project: Dose & Dial Shopify Theme Redesign

## Architecture
Dose & Dial is a premium coffee bar and home-barista storefront ("Precision for Every Pour").
The theme is rebuilt on Fashe 2.0.2 Online Store 2.0 Theme Blocks architecture:
- Core Stylesheet: `assets/base.css` (centralized styling consuming CSS custom property tokens).
- Dynamic Token Injection: `snippets/theme-styles.liquid` (binds `:root` and `.color-scheme` to theme settings).
- Configuration: `config/settings_schema.json` and `config/settings_data.json`.
- Main Layout: `layout/theme.liquid` (loading Google Fonts, Google font tokens, header/footer section groups).
- Section Architecture: Sections in `sections/` consuming Theme Blocks from `blocks/` and snippets from `snippets/`.
- Cart Engine: Server-side Section Rendering API (`CART_SECTIONS = ['cart-drawer', 'cart-icon-bubble']`) in `assets/theme.js`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Dose & Dial Color Tokens | Custom properties: `#F7F3EB`, `#FCFAF6`, `#FFFFFF`, `#111111`, `#2A1D17`, `#7A5736`, `#9A6238`, `#E7E0D6`, `#77716B` with 60/25/10/5 visual balance | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Geometric Sans-Serif Typography | Manrope / Inter font stack with responsive hierarchy, uppercase micro-labels, and subtle letter spacing | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Button Radius & UI Tokens | 2–8px button radius (`radius_base: 4`, `radius_media: 6`) applied storefront-wide via tokens | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Theme Settings Defaults | Updated `settings_schema.json` and `settings_data.json` with Dose & Dial defaults | M1 | ORIGINAL_REQUEST §R1 |
| 5 | Announcement Bar | "FREE STANDARD SHIPPING ON ORDERS OVER €55" with black/espresso background (`scheme_3`) and cream text | M2 | ORIGINAL_REQUEST §R2 |
| 6 | Desktop Header & Navigation | Left wordmark "Dose & Dial", center nav (Shop, Espresso Tools, Coffee Station, Brewing, About), right search/cart | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Sticky Header Compact Scroll | Smooth scroll listener toggling `.header-wrapper--scrolled` for compact format with subtle border | M2 | ORIGINAL_REQUEST §R2 |
| 8 | Mobile Header & Navigation Drawer | Responsive drawer navigation with accessible touch targets (≥ 44px), search, and cart | M2 | ORIGINAL_REQUEST §R2 |
| 9 | Editorial Hero Section | "PRECISION FOR EVERY POUR.", micro-label "DOSE • DIAL • BREW", dual CTAs, desktop & mobile image settings | M3 | ORIGINAL_REQUEST §R3 |
| 10 | Featured Collections | "BUILD YOUR COFFEE BAR", subheading, 4 category cards with subtle image hover zoom | M3 | ORIGINAL_REQUEST §R3 |
| 11 | Best Sellers Grid | "ESSENTIALS FOR BETTER ESPRESSO" dynamic product grid with empty-state fallback | M3 | ORIGINAL_REQUEST §R3 |
| 12 | Editorial Brand Story | "CRAFT YOUR PERFECT SHOT.", philosophy copy, "OUR STORY" CTA, lifestyle imagery block | M3 | ORIGINAL_REQUEST §R3 |
| 13 | Why Dose & Dial Value Pillars | 4 minimalist value pillars (01 Precision, 02 Quality, 03 Simplicity, 04 Coffee Obsession) | M3 | ORIGINAL_REQUEST §R3 |
| 14 | Workflow Espresso Ritual Section | Dedicated 3-step ritual layout (01 DOSE / 02 DIAL / 03 BREW) with schema, blocks, and responsive CSS | M3 | ORIGINAL_REQUEST §R3 |
| 15 | Newsletter Section | "JOIN THE BAR." with coffee tips & updates copy | M3 | ORIGINAL_REQUEST §R3 |
| 16 | Editorial Homepage Template | Curated `templates/index.json` layout chaining all 8 sections in branded order | M3 | ORIGINAL_REQUEST §R3 |
| 17 | Branded Product Card | Off-white card (`#FCFAF6`), subtle border (`#E7E0D6`), secondary hover image, discreet quick-add, genuine sale badge | M4 | ORIGINAL_REQUEST §R4 |
| 18 | Product Detail Page (PDP) Layout | Left high-res media gallery, right structured info (micro-label, title, dynamic price, snippet, picker, add to cart) | M4 | ORIGINAL_REQUEST §R4 |
| 19 | Conditional Product Accordions | Description, What's Included, Specifications, Shipping, Returns rendered conditionally (`{% if content != blank %}`) | M4 | ORIGINAL_REQUEST §R4 |
| 20 | PDP Trust Badges | New block: "Secure checkout", "Fast dispatch", "Designed for the home barista" with clean SVGs | M4 | ORIGINAL_REQUEST §R4 |
| 21 | Ajax Cart Drawer | Slide-out cart with line items, thumbnails, variant info, quantity controls, price, remove action, checkout CTA | M5 | ORIGINAL_REQUEST §R5 |
| 22 | Dynamic Free Shipping Bar | Calculates difference from €55 threshold ("€X away from FREE SHIPPING" / "FREE STANDARD SHIPPING UNLOCKED") | M5 | ORIGINAL_REQUEST §R5 |
| 23 | Predictive Search & 404 Page | Search drawer empty state ("NOTHING YET.") and custom 404 page ("LOOKS LIKE THIS SHOT DIDN'T DIAL IN.") | M5 | ORIGINAL_REQUEST §R5 |
| 24 | 4-Column Branded Footer | Seville business info (Calle Pintor Roldán 3, 41940 Sevilla, Spain \| +34 648 273 811 \| xaviborja1@hotmail.com), dynamic copyright, policies | M5 | ORIGINAL_REQUEST §R5 |
| 25 | E2E Testing & Quality Gate | Automated verification suite: JSON validity, Liquid tag balance, syntax, responsive overflow, motion preference | M6 | ORIGINAL_REQUEST §R6 |
| 26 | Git Commit & Push | Stage all changes, clean git status, descriptive commits, push to `origin/master` (`brittstrohman-maker/xaviborja`) | M6 | ORIGINAL_REQUEST §R6 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Design System, Tokens & Typography | R1: `snippets/theme-styles.liquid`, `layout/theme.liquid`, `config/settings_*.json`, `assets/base.css` | none | DONE |
| M2 | Header, Announcement Bar & Navigation | R2: `sections/header.liquid`, `sections/announcement-bar.liquid`, `sections/header-group.json`, `assets/theme.js` | M1 | DONE |
| M3 | Editorial Homepage Sections | R3: `templates/index.json`, `sections/hero.liquid`, `sections/collection-list.liquid`, `sections/workflow.liquid`, etc. | M1 | DONE |
| M4 | Product Card & PDP Architecture | R4: `snippets/product-card.liquid`, `sections/main-product.liquid`, `blocks/accordion.liquid`, `blocks/trust-badges.liquid`, `templates/product.json` | M1 | DONE |
| M5 | Cart Drawer, Search, Global Pages & Footer | R5: `sections/cart-drawer.liquid`, `snippets/cart-summary.liquid`, `sections/predictive-search.liquid`, `sections/footer.liquid`, `templates/404.json` | M1 | DONE |
| M6 | Final Acceptance, Quality Gate, Git Push | R6: E2E test pass (Tiers 1-4), adversarial hardening (Tier 5), git commit & push to `origin/master` | M1-M5 | IN_PROGRESS |

## Interface Contracts
### Design Tokens ↔ Storefront Components
- `--color-background`: RGB space triplet used with `rgb(var(--color-background))`.
- `--color-text`: RGB space triplet for body typography.
- `--color-button` / `--color-button-label`: Primary button fills and labels.
- `--color-accent`: Copper accent `#9A6238` used for highlights and badges.
- `--color-border`: Light Taupe `#E7E0D6` for subtle borders.
- `--radius-base`: Configured to `4px` in theme settings (clamped 2–8px).
- `--radius-media`: Configured to `6px` in theme settings.
- `--font-heading` / `--font-body`: Manrope, Inter, sans-serif.

### Cart API ↔ Free Shipping Bar
- `cart.total_price`: In cents. Threshold: `5500` cents (€55.00).
- Server-side Section Rendering API endpoint `/cart?sections=cart-drawer,cart-icon-bubble`.
- Calculation: `threshold | minus: cart.total_price`.

## Code Layout & Write Ownership
- **Milestone M1**: Exclusively owned `snippets/theme-styles.liquid`, `config/settings_schema.json`, `config/settings_data.json`, Google font inclusions in `layout/theme.liquid`, and `:root` design token rules in `assets/base.css`. [DONE]
- **Milestone M2**: Exclusively owned `sections/header.liquid`, `sections/announcement-bar.liquid`, `sections/header-group.json`, and header-specific scroll logic in `assets/theme.js`. [DONE]
- **Milestone M3**: Exclusively owns `templates/index.json`, `sections/workflow.liquid` (new section), and homepage section schemas (`hero.liquid`, `collection-list.liquid`, `multicolumn.liquid`, `image-with-text.liquid`, `newsletter.liquid`). [NEXT]
- **Milestone M4**: Exclusively owns `snippets/product-card.liquid`, `sections/main-product.liquid`, `blocks/accordion.liquid`, `blocks/trust-badges.liquid`, `templates/product.json`.
- **Milestone M5**: Exclusively owns `sections/cart-drawer.liquid`, `snippets/cart-summary.liquid`, `sections/predictive-search.liquid`, `sections/main-404.liquid`, `templates/404.json`, `sections/footer.liquid`, `sections/footer-group.json`, and `locales/en.default.json`.
- **Milestone M6 & Test Suite**: Owns test harness scripts (`tests/run_e2e_tests.ps1`), `.gitignore`, git commit and push operations.

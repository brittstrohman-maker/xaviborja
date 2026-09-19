# TEST_INFRA.md: Opaque-Box E2E Testing Suite Architecture & Specification

**Project**: Dose & Dial Shopify Theme Redesign (`doseydial.myshopify.com`)  
**Tagline**: "Precision for Every Pour"  
**Target Codebase**: `c:\Users\alo\Documents\antigravity\serene-curie\xaviborja`  
**Test Runner**: `tests/run_e2e_tests.ps1` (PowerShell 5.1 native)  
**Specification Reference**: `ORIGINAL_REQUEST.md`, `PROJECT.md`  

---

## 1. Test Philosophy

### 1.1 Opaque-Box Verification Principle
The Dose & Dial E2E testing suite adheres strictly to **opaque-box (black-box)** testing methodology:
- **Contract-Driven**: Tests assert observable external behavior, schema conformance, Liquid template contract adherence, CSS custom property cascades, and rendered DOM structures.
- **Zero Implementation Coupling**: Tests do NOT depend on internal variable naming, private functions, or transient implementation quirks. They test *what* the system provides according to specifications, not *how* an individual developer phrased intermediate variables.
- **Anti-Facade Integrity**: No test will ever assert trivial identities (e.g. `$true -eq $true`) or bypass real validation. Each test verifies a genuine property derived from `ORIGINAL_REQUEST.md`. If a feature is not yet built, the test MUST fail. When built correctly, it MUST pass.

### 1.2 Determinism, Isolation & Independence
- Each test is completely self-contained and idempotent.
- Tests can be executed in any sequence or isolated by Tier or Feature without altering results.
- Zero external runtime dependencies: The test suite runs natively on Windows PowerShell 5.1 with zero reliance on Node.js, Ruby, or Python in the environment.

### 1.3 Authoritative Output Derivation
Every expected output in this suite is derived exclusively from two authoritative sources:
1. `ORIGINAL_REQUEST.md`: User's comprehensive requirements R1 through R6 and Acceptance Criteria.
2. `PROJECT.md`: Master architectural blueprint, 26-feature inventory, and interface contracts.

---

## 2. 4-Tier Test Architecture

```
+-----------------------------------------------------------------------------------+
|                        DOSE & DIAL E2E TEST ARCHITECTURE                          |
+-----------------------------------------------------------------------------------+
|  TIER 1: Feature Verification & Syntactics (>=5 tests / feature across 26 features)|
|  - JSON schema & data validity (25+ files)                                        |
|  - Liquid tag/variable balance & block pair integrity (71 files)                   |
|  - Color tokens, typography, button radius, navigation, homepage sections,         |
|    PDP architecture, trust badges, cart shipping bar, 404, footer, git status      |
+-----------------------------------------------------------------------------------+
|  TIER 2: Boundary & Corner Conditions (12 tests)                                  |
|  - Cart threshold boundary values (0c, 5499c, 5500c, 8000c)                       |
|  - Conditional rendering with blank vs populated metafields/content               |
|  - Zero search results empty-state triggers                                       |
|  - Button radius clamping within 2-8px boundary                                   |
|  - Single-variant vs multi-variant card action routing                            |
+-----------------------------------------------------------------------------------+
|  TIER 3: Cross-Feature Integration Combinations (10 tests)                        |
|  - Settings JSON -> CSS Custom Property cascade -> Component class usage          |
|  - Announcement Bar €55 threshold <-> Cart Drawer €55 threshold synchronization   |
|  - PDP Main Section block schema <-> blocks/*.liquid physical registration        |
|  - Section Rendering API endpoint registration in theme.js <-> sections/          |
|  - Footer legal navigation <-> Shopify standard policy routes                     |
+-----------------------------------------------------------------------------------+
|  TIER 4: Real-World Customer Scenarios (8 tests)                                  |
|  - Scenario A: Storefront Discovery & Header Navigation Ritual                     |
|  - Scenario B: Product Exploration, Micro-Labels & Accordion Inspection           |
|  - Scenario C: Line Item Addition & Dynamic Free Shipping Unlocking               |
|  - Scenario D: Search Drawer Predictive Empty State & 404 Recovery Journey        |
|  - Scenario E: Mobile Viewport Touch Compliance (>=44px) & Motion Preferences     |
+-----------------------------------------------------------------------------------+
```

---

## 3. Feature Inventory Mapping (26 Features)

| Feature ID | Feature Name | Milestone | Authoritative Source | Target Files Evaluated | Tier 1 Tests |
|---|---|---|---|---|---|
| **F01** | Dose & Dial Color Tokens | M1 | ORIGINAL_REQUEST §R1 | `config/settings_data.json`, `snippets/theme-styles.liquid`, `assets/base.css` | 5 |
| **F02** | Geometric Sans-Serif Typography | M1 | ORIGINAL_REQUEST §R1 | `layout/theme.liquid`, `assets/base.css`, `snippets/theme-styles.liquid` | 5 |
| **F03** | Button Radius & UI Tokens (2–8px) | M1 | ORIGINAL_REQUEST §R1 | `config/settings_data.json`, `config/settings_schema.json`, `assets/base.css` | 5 |
| **F04** | Theme Settings Defaults | M1 | ORIGINAL_REQUEST §R1 | `config/settings_schema.json`, `config/settings_data.json` | 5 |
| **F05** | Announcement Bar (€55 Free Shipping) | M2 | ORIGINAL_REQUEST §R2 | `sections/announcement-bar.liquid`, `sections/header-group.json`, `config/settings_data.json` | 5 |
| **F06** | Desktop Header & Navigation | M2 | ORIGINAL_REQUEST §R2 | `sections/header.liquid`, `sections/header-group.json` | 5 |
| **F07** | Sticky Header Compact Scroll | M2 | ORIGINAL_REQUEST §R2 | `assets/theme.js`, `sections/header.liquid`, `assets/base.css` | 5 |
| **F08** | Mobile Header & Navigation Drawer | M2 | ORIGINAL_REQUEST §R2 | `sections/header.liquid`, `assets/base.css`, `assets/theme.js` | 5 |
| **F09** | Editorial Hero Section | M3 | ORIGINAL_REQUEST §R3 | `sections/hero.liquid`, `templates/index.json` | 5 |
| **F10** | Featured Collections ("BUILD YOUR COFFEE BAR") | M3 | ORIGINAL_REQUEST §R3 | `sections/collection-list.liquid`, `templates/index.json`, `assets/base.css` | 5 |
| **F11** | Best Sellers Grid ("ESSENTIALS FOR BETTER ESPRESSO") | M3 | ORIGINAL_REQUEST §R3 | `sections/featured-collection.liquid`, `templates/index.json` | 5 |
| **F12** | Editorial Brand Story ("CRAFT YOUR PERFECT SHOT.") | M3 | ORIGINAL_REQUEST §R3 | `sections/image-with-text.liquid`, `templates/index.json` | 5 |
| **F13** | Why Dose & Dial (4 Value Pillars) | M3 | ORIGINAL_REQUEST §R3 | `sections/multicolumn.liquid`, `templates/index.json` | 5 |
| **F14** | Workflow Espresso Ritual Section (01/02/03) | M3 | ORIGINAL_REQUEST §R3 | `sections/workflow.liquid`, `templates/index.json` | 5 |
| **F15** | Newsletter Section ("JOIN THE BAR.") | M3 | ORIGINAL_REQUEST §R3 | `sections/newsletter.liquid`, `templates/index.json` | 5 |
| **F16** | Editorial Homepage Template Sequence | M3 | ORIGINAL_REQUEST §R3 | `templates/index.json` | 5 |
| **F17** | Branded Product Card | M4 | ORIGINAL_REQUEST §R4 | `snippets/product-card.liquid`, `assets/base.css` | 5 |
| **F18** | Product Detail Page (PDP) Layout | M4 | ORIGINAL_REQUEST §R4 | `sections/main-product.liquid`, `templates/product.json`, `assets/base.css` | 5 |
| **F19** | Conditional Product Accordions | M4 | ORIGINAL_REQUEST §R4 | `blocks/accordion.liquid`, `templates/product.json` | 5 |
| **F20** | PDP Trust Badges | M4 | ORIGINAL_REQUEST §R4 | `blocks/trust-badges.liquid`, `templates/product.json`, `assets/base.css` | 5 |
| **F21** | Ajax Cart Drawer | M5 | ORIGINAL_REQUEST §R5 | `sections/cart-drawer.liquid`, `snippets/cart-items.liquid`, `assets/theme.js` | 5 |
| **F22** | Dynamic Free Shipping Bar (€55 Threshold) | M5 | ORIGINAL_REQUEST §R5 | `snippets/cart-summary.liquid`, `sections/cart-drawer.liquid`, `locales/en.default.json` | 5 |
| **F23** | Predictive Search & 404 Page | M5 | ORIGINAL_REQUEST §R5 | `sections/predictive-search.liquid`, `sections/main-404.liquid`, `templates/404.json` | 5 |
| **F24** | 4-Column Branded Footer (Seville Business Details)| M5 | ORIGINAL_REQUEST §R5 | `sections/footer.liquid`, `sections/footer-group.json` | 5 |
| **F25** | E2E Testing & Quality Gate (Syntax & Overflow) | M6 | ORIGINAL_REQUEST §R6 | All JSON & Liquid files, `assets/base.css` | 5 |
| **F26** | Git Commit & Push Readiness | M6 | ORIGINAL_REQUEST §R6 | Git configuration, `.gitignore`, remote repository tracking | 5 |

---

## 4. Test Suite Specification & Semantics

### 4.1 Tier 1: Feature Verification & Syntactics Specification (130 Tests)

#### F01: Dose & Dial Color Tokens
- `F01-01`: Warm Cream `#F7F3EB` configured in `settings_data.json` or `theme-styles.liquid`.
- `F01-02`: Soft Off-White `#FCFAF6` configured in theme tokens for card and page backgrounds.
- `F01-03`: Deep Espresso `#2A1D17` and Matte Black `#111111` defined for typography and dark schemes.
- `F01-04`: Copper Accent `#9A6238` and Warm Walnut `#7A5736` defined in theme tokens.
- `F01-05`: Light Taupe `#E7E0D6` defined for delicate border tokens.

#### F02: Geometric Sans-Serif Typography
- `F02-01`: Manrope or Inter font family reference loaded in `layout/theme.liquid` or `base.css`.
- `F02-02`: Uppercase micro-label styling (`text-transform: uppercase`) present for subtitles and eyebrows.
- `F02-03`: Letter-spacing defined for micro-labels (`letter-spacing: 0.08em` to `0.15em`).
- `F02-04`: Responsive typographic scale defined for heading levels (h1 through h6) in `base.css`.
- `F02-05`: Heading font-family variables properly bound in `theme-styles.liquid`.

#### F03: Button Radius & UI Tokens
- `F03-01`: Button border-radius defined between `2px` and `8px` in `settings_data.json`.
- `F03-02`: `radius_base` setting documented in `settings_schema.json`.
- `F03-03`: CSS custom property `--radius-base` assigned to buttons in `base.css`.
- `F03-04`: Media radius `--radius-media` configured between `0px` and `12px`.
- `F03-05`: UI button hover elevation or color transition defined in `base.css`.

#### F04: Theme Settings Defaults
- `F04-01`: `config/settings_schema.json` parses as 100% valid JSON.
- `F04-02`: `config/settings_data.json` parses as 100% valid JSON.
- `F04-03`: Color schemes object present in `settings_data.json` (`color_schemes` / `scheme_*`).
- `F04-04`: Primary storefront scheme matches Dose & Dial warm cream/off-white background.
- `F04-05`: Inverted dark scheme matches Matte Black/Espresso with cream text.

#### F05: Announcement Bar
- `F05-01`: Copy "FREE STANDARD SHIPPING ON ORDERS OVER €55" present in `sections/header-group.json` or `settings_data.json` or `announcement-bar.liquid`.
- `F05-02`: Announcement bar section contains announcement text schema block or setting.
- `F05-03`: Announcement bar supports color scheme selection (dark/espresso background).
- `F05-04`: Announcement bar Liquid template parses with balanced tags and blocks.
- `F05-05`: Announcement bar rendered in `header-group.json`.

#### F06: Desktop Header & Navigation
- `F06-01`: Brand wordmark / text "Dose & Dial" present in `header.liquid` or header settings.
- `F06-02`: Navigation links defined for Shop, Espresso Tools, Coffee Station, Brewing, About.
- `F06-03`: Search icon or toggle present in header right group.
- `F06-04`: Cart icon/bubble present in header right group linking to `/cart`.
- `F06-05`: Header section schema valid and includes desktop navigation menu selector.

#### F07: Sticky Header Compact Scroll
- `F07-01`: Scroll listener event registered in `assets/theme.js`.
- `F07-02`: Scrolled class `.header-wrapper--scrolled` or `.header--sticky` toggled dynamically.
- `F07-03`: CSS rule in `assets/base.css` styles sticky header on scroll.
- `F07-04`: Subtle border transition rule defined for scrolled header.
- `F07-05`: Header wrapper structure supports sticky positioning (`position: sticky`).

#### F08: Mobile Header & Navigation Drawer
- `F08-01`: Mobile menu toggle button present with accessible aria attributes.
- `F08-02`: Mobile navigation drawer `#MenuDrawer` or `.menu-drawer` defined in markup.
- `F08-03`: Touch target minimum dimension (>= 44px) enforced for mobile navigation items.
- `F08-04`: Mobile drawer includes search and cart access.
- `F08-05`: Mobile drawer open/close transition handled smoothly without layout shift.

#### F09: Editorial Hero Section
- `F09-01`: Editorial headline "PRECISION FOR EVERY POUR." configured in `index.json` or `hero.liquid`.
- `F09-02`: Micro-label "DOSE • DIAL • BREW" configured in hero settings.
- `F09-03`: Subtext "Premium tools for home baristas who take every shot seriously." present.
- `F09-04`: Primary CTA "SHOP ESPRESSO TOOLS" and Secondary CTA "EXPLORE THE COLLECTION" configured.
- `F09-05`: Hero section schema supports separate desktop and mobile image pickers.

#### F10: Featured Collections ("BUILD YOUR COFFEE BAR")
- `F10-01`: Section heading "BUILD YOUR COFFEE BAR" configured in `index.json` or `collection-list.liquid`.
- `F10-02`: Subheading "Everything you need to refine your espresso setup." configured.
- `F10-03`: 4 visual category cards configured: Espresso Tools, Coffee Station, Brewing Essentials, Milk & Latte Art.
- `F10-04`: Subtle image hover zoom transition (`transform: scale(...)`) styled in `assets/base.css`.
- `F10-05`: Collection card links route to valid collection handles.

#### F11: Best Sellers Grid ("ESSENTIALS FOR BETTER ESPRESSO")
- `F11-01`: Best Sellers heading "ESSENTIALS FOR BETTER ESPRESSO" configured.
- `F11-02`: Subtext "Precision tools designed to make every step of your workflow better." present.
- `F11-03`: Product grid dynamically binds to merchant-selected Shopify collection.
- `F11-04`: Empty state fallback gracefully handles empty collection without syntax crash.
- `F11-05`: Grid layout supports responsive columns (2 mobile, 4 desktop).

#### F12: Editorial Brand Story ("CRAFT YOUR PERFECT SHOT.")
- `F12-01`: Section headline "CRAFT YOUR PERFECT SHOT." configured.
- `F12-02`: Philosophy copy emphasizing precision, craft, and espresso ritual present.
- `F12-03`: Call to action "OUR STORY" link present.
- `F12-04`: Editorial layout features lifestyle imagery block alongside storytelling text.
- `F12-05`: Image-with-text Liquid template parses with balanced tags.

#### F13: Why Dose & Dial (4 Value Pillars)
- `F13-01`: 4 value pillars present: 01 Precision, 02 Quality, 03 Simplicity, 04 Coffee Obsession.
- `F13-02`: Pillar numbering/eyebrow formatting applied consistently.
- `F13-03`: Pillar layout structured in multi-column or grid formation.
- `F13-04`: Minimalist card styling using Dose & Dial off-white/taupe borders.
- `F13-05`: Section schema supports flexible column blocks.

#### F14: Workflow Espresso Ritual Section (01 DOSE / 02 DIAL / 03 BREW)
- `F14-01`: Dedicated 3-step espresso ritual layout configured in `index.json`.
- `F14-02`: Step 01: DOSE - "Start with consistency." present.
- `F14-03`: Step 02: DIAL - "Fine-tune your grind and extraction." present.
- `F14-04`: Step 03: BREW - "Enjoy the result." present.
- `F14-05`: Responsive layout: horizontal timeline on desktop, vertical steps on mobile.

#### F15: Newsletter Section ("JOIN THE BAR.")
- `F15-01`: Newsletter headline "JOIN THE BAR." configured in `index.json` or `newsletter.liquid`.
- `F15-02`: Coffee tips, calibration rituals, and equipment updates copy present.
- `F15-03`: Native Shopify customer form tag `{% form 'customer' ... %}` used.
- `F15-04`: Hidden contact tags `[newsletter]` included in submission.
- `F15-05`: Accessible email input field with label and submit button.

#### F16: Editorial Homepage Template Sequence
- `F16-01`: `templates/index.json` parses as valid JSON with standard OS 2.0 structure.
- `F16-02`: Homepage contains at least 7 branded editorial sections in `order` array.
- `F16-03`: Hero section positioned as first main body section.
- `F16-04`: Workflow or Brand Story section included before newsletter.
- `F16-05`: Newsletter section positioned towards bottom of sequence.

#### F17: Branded Product Card
- `F17-01`: Card background styled with Soft Off-White (`#FCFAF6`) in `assets/base.css`.
- `F17-02`: Card border styled with Light Taupe (`#E7E0D6`) in `assets/base.css`.
- `F17-03`: Secondary hover image logic present in `snippets/product-card.liquid`.
- `F17-04`: Discreet quick-add button present without aggressive countdowns.
- `F17-05`: Sale badge renders strictly when `compare_at_price > price` (no fake urgency badges).

#### F18: Product Detail Page (PDP) Layout
- `F18-01`: Media gallery `<product-gallery>` left-aligned on desktop in `main-product.liquid`.
- `F18-02`: High-resolution eager loading (`loading: eager`, `fetchpriority: high`) on primary media.
- `F18-03`: Structured product info `<product-info>` right-aligned with sticky capability.
- `F18-04`: Uppercase category micro-label (eyebrow) rendered before product title.
- `F18-05`: Variant picker, quantity selector, and primary Add to Cart button present in `templates/product.json`.

#### F19: Conditional Product Accordions
- `F19-01`: `blocks/accordion.liquid` enforces strict conditionality (`{% if content != blank %}`).
- `F19-02`: Empty content prevents `<details>` DOM node from rendering.
- `F19-03`: Description accordion correctly accesses `product.description` when heading is Description.
- `F19-04`: `templates/product.json` configures 5 standard accordions (Description, What's Included, Specifications, Shipping, Returns).
- `F19-05`: Accordion summary contains accessible chevron icon toggle.

#### F20: PDP Trust Badges
- `F20-01`: Trust badges component exists (`blocks/trust-badges.liquid` or snippet).
- `F20-02`: "Secure checkout" badge text and icon present.
- `F20-03`: "Fast dispatch" badge text and icon present.
- `F20-04`: "Designed for the home barista" badge text and icon present.
- `F20-05`: Trust badges configured inside `templates/product.json` block sequence.

#### F21: Ajax Cart Drawer
- `F21-01`: Slide-out dialog `#CartDrawer` defined in `sections/cart-drawer.liquid`.
- `F21-02`: Line items render product thumbnail, title, variant, and quantity inputs.
- `F21-03`: Quantity adjust buttons and item removal actions update without page reload.
- `F21-04`: Subtotal and Checkout button dynamically reflect cart state.
- `F21-05`: Server-side Section Rendering API endpoint `cart-drawer` registered in `theme.js`.

#### F22: Dynamic Free Shipping Bar (€55 Threshold)
- `F22-01`: Threshold configured to `55` / `5500` cents in theme settings or Liquid calculation.
- `F22-02`: Remaining amount calculation: `threshold | minus: cart.total_price`.
- `F22-03`: Unfulfilled string matches "away from FREE SHIPPING" (e.g. `€18 away from FREE SHIPPING`).
- `F22-04`: Unlocked string matches "FREE STANDARD SHIPPING UNLOCKED".
- `F22-05`: Progress fill percentage dynamically calculated: `cart.total_price * 100 / threshold`.

#### F23: Predictive Search & 404 Page
- `F23-01`: Predictive search drawer `#SearchDrawer` present in header group.
- `F23-02`: Empty search results state displays "NOTHING YET." in `predictive-search.liquid`.
- `F23-03`: Empty search suggestion copy: "Try another search or explore our coffee bar essentials."
- `F23-04`: 404 page headline displays "LOOKS LIKE THIS SHOT DIDN'T DIAL IN."
- `F23-05`: 404 page CTA button displays "BACK TO THE COFFEE BAR" linking to all products.

#### F24: 4-Column Branded Footer (Seville Business Details)
- `F24-01`: 4-column footer structure configured in `sections/footer.liquid` and `footer-group.json`.
- `F24-02`: Physical address "Calle Pintor Roldán 3, 41940 Sevilla, Spain" present verbatim.
- `F24-03`: Business phone "+34 648 273 811" present verbatim.
- `F24-04`: Business email "xaviborja1@hotmail.com" present verbatim.
- `F24-05`: Dynamic copyright `© {{ 'now' | date: '%Y' }} Dose & Dial` present in footer bottom.

#### F25: E2E Testing & Quality Gate (Syntax & Overflow)
- `F25-01`: All 25 JSON files parse strictly via `ConvertFrom-Json` with 0 syntax errors.
- `F25-02`: All 71 Liquid files pass balanced tag check (`{% %}` and `{{ }}`).
- `F25-03`: All 71 Liquid files pass balanced block check (`if/endif`, `for/endfor`, `case/endcase`, `form/endform`).
- `F25-04`: All embedded `{% schema %}` JSON blocks parse strictly with 0 syntax errors.
- `F25-05`: CSS includes `prefers-reduced-motion: reduce` media query in `assets/base.css`.

#### F26: Git Commit & Push Readiness
- `F26-01`: Git working repository initialized with valid git configuration.
- `F26-02`: Current branch set to `master`.
- `F26-03`: Remote origin configured to `https://github.com/brittstrohman-maker/xaviborja`.
- `F26-04`: `.agents/` metadata directory excluded in `.gitignore`.
- `F26-05`: No unwanted artifacts staged outside theme structure.

---

### 4.2 Tier 2: Boundary & Corner Conditions Specification (12 Tests)

- `T2-01` **Empty Cart Threshold State**: When `cart.total_price == 0`, remaining amount is exactly €55.00 (`5500` cents) and progress bar is 0%.
- `T2-02` **Threshold Boundary Minus 1 Cent**: When `cart.total_price == 5499` cents (€54.99), status indicates €0.01 away from free shipping (not unlocked).
- `T2-03` **Exact Threshold Equality**: When `cart.total_price == 5500` cents (€55.00), remaining is 0, status transitions to "FREE STANDARD SHIPPING UNLOCKED", and progress bar is 100%.
- `T2-04` **Threshold Overfill**: When `cart.total_price > 5500` cents (€80.00), remaining is <= 0, bar remains clamped at 100%, and status remains UNLOCKED without negative remaining amounts.
- `T2-05` **Blank Accordion Suppression**: In `blocks/accordion.liquid`, if `heading` is set but `content` and `page` are both empty, the `<details>` tag is suppressed entirely (`{% if content != blank %}`).
- `T2-06` **Description Accordion Fallback**: If accordion heading is "Description" and `block.settings.content` is blank, it cleanly falls back to `product.description`.
- `T2-07` **Single-Variant Direct Add to Cart**: Product card for a single-variant product renders direct `<form action="/cart/add">` rather than generic collection redirect.
- `T2-08` **Multi-Variant Option Select Action**: Product card for a multi-variant product renders a link to `product.url` ("Choose options") to avoid invalid default additions.
- `T2-09` **Zero Search Query State**: Predictive search drawer opened before keystroke entry provides coffee category chips without throwing undefined error.
- `T2-10` **Zero Search Results State**: Predictive search with no matching items renders "NOTHING YET." and suggestion copy without broken layout.
- `T2-11` **Button Radius Lower/Upper Boundary**: Theme settings button radius value `radius_base` is strictly clamped between `2` and `8` (inclusive).
- `T2-12` **Product Compare Price Sale Suppression**: Product card suppresses sale badge when `compare_at_price <= price` or when `compare_at_price` is blank.

---

### 4.3 Tier 3: Cross-Feature Integration Combinations Specification (10 Tests)

- `T3-01` **Token Cascade Integration**: Theme settings schema definitions (`settings_schema.json`) map to theme settings data (`settings_data.json`), inject into `:root` in `snippets/theme-styles.liquid`, and are consumed as CSS variables in `assets/base.css`.
- `T3-02` **Shipping Bar <-> Announcement Bar Threshold Sync**: The €55 threshold advertised in `announcement-bar.liquid` / `header-group.json` strictly matches the free shipping threshold configured for the cart drawer (`cart_free_shipping_threshold: 55`).
- `T3-03` **PDP Section <-> Theme Blocks Registration**: Every theme block instantiated in `templates/product.json` (`title`, `price`, `vendor`, `variant-picker`, `quantity`, `buy-buttons`, `trust-badges`, `accordion`) has a corresponding physical template in `blocks/*.liquid`.
- `T3-04` **Cart Engine Section Rendering API Sync**: `assets/theme.js` requests sections `['cart-drawer', 'cart-icon-bubble']`, which strictly correspond to existing sections `sections/cart-drawer.liquid` and `sections/cart-icon-bubble.liquid`.
- `T3-05` **Footer Legal Policies <-> Standard Shopify Routes**: Links in `sections/footer.liquid` route to standard Shopify policy objects (`shop.refund_policy`, `shop.privacy_policy`, `shop.terms_of_service`, `shop.shipping_policy`) or standard `/policies/*` routes.
- `T3-06` **Header Navigation <-> Homepage Collection Handles**: Navigation handles in `header.liquid` (Espresso Tools, Coffee Station, Brewing) match collection cards referenced in `templates/index.json`.
- `T3-07` **Product Card Quick-Add <-> Cart Drawer Ajax Listener**: Form submitted by `snippets/product-card.liquid` dispatches event captured by `theme.js` to open `#CartDrawer`.
- `T3-08` **Color Scheme Cascade to Dark Components**: Dark color scheme (`scheme_3`) defined with Matte Black/Espresso background applies to Announcement Bar, Footer, and Header Scrolled states consistently.
- `T3-09` **404 Recovery <-> Store Catalog Route**: CTA button on 404 page ("BACK TO THE COFFEE BAR") links to `routes.all_products_collection_url`.
- `T3-10` **Mobile Navigation Drawer <-> Search Drawer Coexistence**: Mobile navigation drawer and predictive search dialog coexist without modal trapping or backdrop conflicts in DOM.

---

### 4.4 Tier 4: Real-World Customer Scenarios Specification (8 Tests)

- `T4-01` **Scenario A: Home Barista Discovery Journey**: Customer visits storefront -> Announcement bar advertises €55 shipping -> Sticky header stays visible on scroll -> Hero CTA invites user to "SHOP ESPRESSO TOOLS" -> 4 Featured Collection cards highlight Espresso Tools, Coffee Station, Brewing Essentials, Milk & Latte Art.
- `T4-02` **Scenario B: Ritual Workflow & Brand Story Engagement**: Customer scrolls through homepage -> Encounters 3-Step Ritual ("01 DOSE", "02 DIAL", "03 BREW") -> Reads "CRAFT YOUR PERFECT SHOT." brand story -> Learns 4 value pillars ("01 Precision", "02 Quality", "03 Simplicity", "04 Coffee Obsession") -> Newsletter invites to "JOIN THE BAR.".
- `T4-03` **Scenario C: Product Detail Page & Trust Verification**: Customer views PDP -> Gallery eager loads primary media -> Category micro-label "ESPRESSO TOOLS" -> Dynamic price display -> Trust badges confirm "Secure checkout", "Fast dispatch", "Designed for the home barista" -> 5 accordions provide technical details without empty container rendering.
- `T4-04` **Scenario D: Dynamic Free Shipping Cart Progression**: Customer adds €37 tamper to cart -> Drawer slides out -> Shipping bar reads "€18 away from FREE SHIPPING" -> Customer adds €22 distribution tool (Total: €59) -> Shipping bar dynamically updates to "FREE STANDARD SHIPPING UNLOCKED" with 100% progress.
- `T4-05` **Scenario E: Predictive Search Exploration & Recovery**: Customer opens search drawer -> Enters query with 0 results -> Clean empty state displays "NOTHING YET." and "Try another search or explore our coffee bar essentials." -> Direct link to catalog prevents abandonment.
- `T4-06` **Scenario F: 404 Error Encounter & Graceful Return**: Customer hits invalid URL -> Branded 404 page displays "LOOKS LIKE THIS SHOT DIDN'T DIAL IN." with extraction error eyebrow -> "BACK TO THE COFFEE BAR" button routes customer back to catalog.
- `T4-07` **Scenario G: Seville Business Verification & Footer Transparency**: Customer checks footer for merchant credentials -> Verifies genuine business information: "Calle Pintor Roldán 3, 41940 Sevilla, Spain", phone "+34 648 273 811", email "xaviborja1@hotmail.com" -> Verifies dynamic copyright `© {{ 'now' | date: '%Y' }} Dose & Dial`.
- `T4-08` **Scenario H: Mobile Responsive Touch & Motion Accessibility**: Mobile barista on 375px viewport -> All touch targets (menu toggle, quantity buttons, accordions, quick-add) maintain >= 44px hit area -> Zero horizontal overflow -> Animation respects `prefers-reduced-motion: reduce`.

---

## 5. Test Suite Execution & CLI Specification

### 5.1 Execution Command
```powershell
powershell -ExecutionPolicy Bypass -File tests/run_e2e_tests.ps1
```

### 5.2 Command Options
```
Parameters:
  -Tier <1|2|3|4|All>       Filter execution by tier (Default: All)
  -Feature <1..26>          Filter Tier 1 execution by Feature ID (1 to 26)
  -VerboseOutput            Display individual assertion traces and debug info
  -JsonOutput <path>        Export test execution results in structured JSON format
```

### 5.3 Exit Code Semantics
- **Exit Code `0`**: 100% of executed assertions passed. Storefront satisfies all evaluated criteria.
- **Exit Code `1`**: One or more assertions failed. Detailed failure breakdown printed to stderr/stdout with file locations, expected values, and actual values.

---

## 6. Coverage Thresholds & Quality Gate

| Tier | Tier Name | Test Count | Pass Threshold for Milestone M6 |
|---|---|---|---|
| **Tier 1** | Feature Verification & Syntactics | 130 | 100% (130 / 130) |
| **Tier 2** | Boundary & Corner Conditions | 12 | 100% (12 / 12) |
| **Tier 3** | Cross-Feature Integration Combinations | 10 | 100% (10 / 10) |
| **Tier 4** | Real-World Customer Scenarios | 8 | 100% (8 / 8) |
| **TOTAL** | Complete Opaque-Box Suite | **160** | **100% (160 / 160)** |

During intermediate milestones (M1 through M5), the test suite serves as an active **Progressive Quality Gate**. As each milestone worker completes their work, the corresponding tier tests transition from FAIL to PASS, providing transparent, tamper-proof verification of genuine progress.

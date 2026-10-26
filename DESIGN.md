# FINORA Design Contract

## Product read

- Product: personal and household finance app for Vietnamese users.
- Platforms: Android first, responsive web preview for design review.
- Register: trust-first utility.
- Style: fresh mint banking: crisp white surfaces on a luminous mint canvas.
- Primary theme: light, with a fully designed dark mode.
- Accent: vivid green `#08C95B`; deep navy `#08082F` anchors text, navigation, and premium cards. Coral is reserved for expense and destructive states.
- Motion: quiet and purposeful, limited to state changes and navigation feedback.
- Voice: calm, direct Vietnamese. No cute copy or artificial urgency.
- Primary action: record a transaction.
- Dials: `DESIGN_VARIANCE=4`, `MOTION_INTENSITY=3`, `VISUAL_DENSITY=4`.

## Layout and component rules

- Compact widths use the five-item bottom dock: `Trang chủ / Giao dịch / + / Ví tiền / Cá nhân`.
- Medium and expanded widths must cap reading content and adapt navigation rather than stretch phone layouts.
- Use one soft radius family and the shared 4-point spacing scale.
- Use opaque white surfaces, generous negative space, mint hairlines, and very soft green-tinted shadows. Avoid decorative glass blur in light mode.
- Money and financial metrics use tabular figures.
- The filled high-contrast action is reserved for the primary action on each screen.
- Icon-only controls are circular. Labeled buttons use the strong 20px squircle radius.
- Member filtering is one color-coded dropdown with no person icons, placed beside the active date range or inside the summary hero.
- Income and positive movement use vivid green; expense copy is always `Chi tiêu` and uses coral. Navy carries totals, neutral data, and high-contrast controls.

## Decisions log

- 2026-08-30: Established the persistent contract from the restored APK handoff and current source.
- 2026-08-30: Added responsive Flutter Web as a live design-review surface. Android remains the release target.
- 2026-08-30: Standardized owner dropdowns, transaction colors, circular quick actions, stronger labeled buttons, month/year selection, and line-chart transaction trends.
- 2026-08-30: Reframed the visual language around the supplied editorial banking reference: cool-paper background, white cards, plum controls, and coral/orange/sky financial highlights.
- 2026-08-30: Replaced the prior palette with the supplied mint banking direction: luminous mint canvas, vivid green actions, deep navy anchors, and green/navy payment cards.


## Android usability pass — 2026-08-31

- Keep the existing mint/navy direction. Use the dark balance hero as the visual anchor, white cash-flow cards, and a calm mint page background. Shared backgrounds no longer render a full-screen decorative blur.
- Separate lifetime available wallet balance from selected-period income/expense. Show actual investment and borrowing totals from DashboardData. Never insert sample financial values, fallback health scores, or unread notification badges into production UI.
- Summary privacy toggle masks all six monetary values in the summary. Health estimates require transaction history and are identified as estimates.
- Dock destinations use equal flexible widths, accessible button/selected semantics, tooltips, and a distinct add transaction action. Large text uses icon navigation with accessible labels. The dock reserves its own layout space so it does not cover the bottom of page content.
- Summary metric columns collapse at narrow widths or enlarged text. Member/date controls wrap rather than forcing all content onto one row.
- Authentication preserves typed email when switching modes, caps form width, wraps footer links, and names the password-visibility action.
- UI review images use explicit test fixtures, not a production account. Scope: summary, health card, and navigation; they are not screenshots of a signed-in Android session.


## Compact overview and period filters — 2026-08-31

- Dashboard keeps available balance, investment/debt links, member/date selectors, income/expense and net cash flow inside one navy card.
- Transaction screen title is Giao dịch. A search icon expands into the input in the same toolbar and hides type tabs until closed. Closing search clears only the query, preserving other filters.
- PeriodPicker returns a typed PeriodSelection. Presets cover complete weeks/months; custom month and custom day remain distinct. The existing single-date picker remains for transaction-entry fields that require one date.
- Transaction filters use wrapped member/type chips, one period row and a category dropdown, with an apply action pinned below scrollable content.
- Category totals/counts and category history share the selected period. The default is this month with only used categories; the filter can be disabled to manage unused categories.
- Asset list uses full-width cards separating title/type, market value, gain/loss, cost basis and quantity. Asset actions retain edit/delete confirmation behavior.
- Verified: 64 Flutter tests passed; Dart analyzer has zero errors (legacy lint warnings remain). Emulator visual review covers transactions, expanded search, period picker, assets and categories. Current changes are hot-reloaded into the active debug session; the earlier exported APK has not been rebuilt for this pass.

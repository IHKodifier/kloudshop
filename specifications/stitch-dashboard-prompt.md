# Stitch Prompt: Merchant Dashboard Overview Design

This document contains the optimized prompt to be fed into Stitch (or a similar UI design subagent) to generate the high-fidelity, premium Merchant Dashboard Overview screen.

---

## Stitch Input Prompt

```markdown
Role: Lead UI/UX Designer & Design System Specialist
Task: Generate a high-fidelity dashboard design mockup for the KloudShop Merchant Dashboard Home (S-10 Screen).

Design Philosophy & Theme:
- Theme: "Alpine Emerald OS"
- Aesthetic: Alpine Minimalism meets Deep Emerald Luxury. Serene, clean, high-precision layout with plenty of whitespace. Avoid unnecessary decoration.
- Colors:
  - Surface Background: Mist Green (#f8faf6)
  - Card/Container Surface: Pure White (#ffffff)
  - Primary Typography/Accents: Deep Forest Green (#003527 / #064e3b)
  - Highlights/Success/CTAs: Vibrant Emerald (#006c49 / #10b981)
  - Warning/Alerts: Refined, desaturated coral (#ba1a1a)
- Typography: 
  - Headings: Outfit (geometric, tight negative letter-spacing for headings)
  - UI/Body/Data: Inter (utilitarian, high-legibility for values, tags, and body text)
- Shapes: Cards must have a 12px (0.75rem) border radius, a 1px soft border (#e2e8f0), and zero shadow by default (Level 1 elevation). Cards transition to Y: 4px, Blur: 12px, 6% black shadow on hover (Level 2 elevation).

Dashboard Layout & Content Requirements (12-Column Desktop Grid):

1. HEADER AREA:
   - Left side: Geometric greeting ("Welcome back, [Name]") in Outfit bold.
   - Right side: Quick stats/quick-actions (e.g., date range selector dropdown with a subtle 1.5px border, search icon, notifications bell icon with unread badge indicator).

2. OVERVIEW KPI CARDS (Top Row - 4 columns each, total 12):
   - Revenue Overview (Last 24 Hours): Large '$12,847' in Outfit. Subtext: '↑ 23% vs yesterday' in green.
   - Orders: '47' in Outfit. Subtext: 'AOV: $273' in Inter gray.
   - Conversion: '3.2%' in Outfit. Subtext: 'Target: 3.5%' in Inter.

3. "NEEDS ATTENTION" PANEL (Main Focus - Above the fold, 8 columns width):
   - Header: '⚠ NEEDS ATTENTION' in bold red/coral color caps.
   - Purpose: Surface critical, actionable operational flags.
   - Card rows (Pure White, high-density, alternating Mist Green background on hover):
     * Row 1: "3 orders pending fulfilment > 24hrs" (links to Orders).
     * Row 2: "SKU #1042 (Widget Pro) — 3 days of stock remaining" with a red label ("Lead time: 12 days - Reorder point exceeded").
     * Row 3: "2 B2B approvals waiting" (links to B2B approvals queue).

4. VERTEX AI INSIGHTS CARD (Right Sidebar - 4 columns width):
   - Styled as a premium glassmorphic container with a subtle Emerald glow border.
   - Header: 'AI INSIGHT' with a small green spark icon.
   - Body: "Widget Pro likely to stockout in 3 days based on current sales velocity and Acme Parts lead times. Suggest reordering 500 units."
   - Action Buttons at the bottom: 
     * Secondary: "Dismiss" (outlined 1.5px Deep Forest Green).
     * Action: "Draft Purchase Order" (solid Vibrant Emerald background, white text).

5. INTERACTIVE ANALYTICS VISUALIZATION (Bottom Section - 12 columns width):
   - An elegant line/grouped bar chart card displaying revenue vs target trends.
   - Clean axes, minimalist grid lines (horizontal only), and a green gradient fill beneath the primary line.
```

# Tasks

- `[x]` Update Product Editor State Logic (`product_editor_provider.dart`)
  - `[x]` Change new product initialization to start with 0 color values and empty variant option values
  - `[x]` Inject default `"Color"` option category in existing product loaded state if not present
  - `[x]` Filter out empty option categories in saving logic before API call
  - `[x]` Output mandatory collapse deactivated variants report to console in Debug environment
  - `[x]` Clean variant SKU generation to avoid leading/trailing/double dashes
- `[x]` Implement Two-Column Options Card (`product_options_card.dart`)
  - `[x]` Build responsive layout: 40/60 split on desktop (>= 900px width), stacked on mobile
  - `[x]` Ensure Color option category is routed to the left column and others to the right
  - `[x]` Handle deletion of the Color category by clearing its values instead of removing it
- `[x]` Refine Option Category Editor UI (`option_category_editor.dart`)
  - `[x]` Change delete icon tooltip to "Don't use color for this product" for the Color category
  - `[x]` Render a bold "No color options defined for this product" message when values list is empty
- `[x]` Resolve Test Scenarios Feedback
  - `[x]` Auto-trigger variants collapse/stock aggregation immediately when schema becomes empty
  - `[x]` Display details/generate instruction card in variants list section if options are defined but variants are empty
- `[x]` Verify changes compile and run correctly

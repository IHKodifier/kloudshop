# Implementation Plan: Journey 3 (Part 2) — Advanced Kloud-Figma Storefront Visual Builder

This plan extends the **Journey 3: DTC Consumer Storefront** visual editor to support a premium Figma-like canvas builder for KloudShop. It includes a simulated macOS browser top-frame, multi-page layout switching, a rich collapsible component stack, user-configurable color presets, pixel-accurate absolute positioning, fullscreen test preview routes, page background styling, and a suite of figma-parity interface features.

---

## User Review Required

> [!IMPORTANT]
> **1. AI Image-to-Theme Expressiveness Guarantee**
> To support future AI visual generation (where administrators upload screenshots of arbitrary Shopify themes or external webpages), our JSON schema and rendering components must act as a **universal e-commerce visual vocabulary**. Our layout primitives (including spacers, stacks, auto layout alignments, margins, and commerce trust badges) are designed to provide the expressive power needed to reconstruct any webpage screenshot.
>
> **2. Photoshop/Illustrator-Style X & Y Coordinate Text Fields**
> For absolutely-positioned elements, we will expose precise **X (Left)**, **Y (Top)**, **W (Width)**, and **H (Height)** text input fields in the styling panel. Changes to these input boxes will immediately update the component's position and dimensions on the canvas.
>
> **3. Interactive Canvas Zoom Scaling**
> We will add zoom control widgets (`- 100% +`) in the top bar. This will scale the central preview canvas viewport from `50%` to `150%` via `Transform.scale`.
>
> **4. Layers Panel Enhancements**
> In the left Component Stack list, each element node will support:
> * **Rename**: Double-clicking a node or modifying its label in the styling sheet updates its display name.
> * **Visibility (Eye Icon)**: Toggle layer visibility to hide/show nodes in the preview viewport (persisted via `hidden` flag).
> * **Lock (Lock Icon)**: Lock a component to prevent selection and mouse-dragging on the canvas.
>
> **5. Figma-Style Auto Layout Options**
> For layout containers in flex mode, we will display:
> * **9-Point Grid Alignment**: A clickable 3x3 alignment box to set alignment (e.g., Top-Left, Center, Bottom-Right) visually.
> * **Individual Padding Fields**: Numeric text boxes to set `Padding Top`, `Padding Bottom`, `Padding Left`, and `Padding Right` independently.

---

## Proposed Changes

### 1. Visual Editor Layout, Page Navigation & Zoom

#### [MODIFY] [wysiwyg_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/wysiwyg_view.dart)
* **Canvas Zoom Scale**:
  * Track double variable `_zoomScale` (default `1.0`).
  * In the top bar, add a center-aligned zoom indicator `- 100% +`. Clicking `+` increases zoom by `0.1` (max `1.5`), `-` decreases by `0.1` (min `0.5`).
* **Keyboard Shortcuts & Key Events**:
  * Wrap the editor body in a `KeyboardListener` or `Focus` widget.
  * Listen for key down events: Undo/Redo, Delete, and Arrow Key nudge triggers.
* **Rename/Lock/Hide Layer State**:
  * Store custom node labels (`customName`), visibility (`hidden`), and lock states (`locked`) inside the layout node JSON properties.
  * Update Left Stack to render eye (visibility) and lock icons, and allow double-click renaming of layer headers.
* **Auto Layout & Position Styling Fields**:
  * Add a 3x3 grid alignment selector.
  * Render separate input fields for `X`, `Y`, `W`, `H` for absolute positioning.
  * Add inputs for individual margins/paddings.
* **Canvas Background & Preset Colors**:
  * Render configurable presets and background parameters (solid, gradient, image with repeats).

### 2. Precise Canvas Rendering & Drag-to-Move

#### [MODIFY] [storefront_preview.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/storefront_preview.dart)
* **Canvas Background Rendering**:
  * Parse canvas background keys from `tokens` to apply solid color backgrounds, linear/radial gradients, background image widgets (with fit, repeat, and opacity), or custom shaders to the main preview container.
* **DragTarget coordinates calculation**:
  * Use `onAcceptWithDetails` to retrieve the absolute screen position of the drop.
  * Convert the global offset to local container coordinates using `RenderBox.globalToLocal(details.offset)` and store as `left` and `top`.
* **Absolute Stacking & Positioned Rendering**:
  * Render absolute layout containers using `Stack` containing `Positioned` children.
  * Add a `GestureDetector(onPanUpdate: ...)` for selected absolute nodes to allow direct mouse-drag repositioning on the canvas.
* **WysiwygFullscreenPreview**:
  * Implement the full-screen simulated deployment screen which renders `StorefrontPreview` alone with a floating "Close Preview" button.

---

## Verification Plan

### Automated Tests
* Update widget tests to assert page switching, canvas background modifications, absolute canvas coordinate modification, and full-screen preview navigation.
* Run tests:
  ```powershell
  flutter test
  ```

### Manual Verification
* Set a Col/Row Layout container to "Absolute" mode in the properties panel.
* Drag a component from the left stack and drop it anywhere. Verify that it stays exactly where it was dropped.
* Click and drag the component to move it. Check that the X/Y coordinates in the Right Config Panel update in real-time.
* Click the "Preview" button to open the full-screen simulated storefront.

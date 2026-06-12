# Hover Highlight Design

## Goal

Add visible feedback while `mxkill` is waiting for a click so the user can see which window will be targeted before they kill it.

## User Experience

When `mxkill` enters picker mode:

- The cursor remains a best-effort crosshair.
- Moving the pointer over a window draws a thin red border around that window.
- Moving to another window moves the border.
- Moving outside a targetable window hides the border.
- Left click keeps the current behavior: select the clicked window and continue to dry-run or signal handling.
- Right click or Escape cancels and removes the overlay.
- Timeout removes the overlay.

The terminal remains the source of textual status. The overlay is only a visual targeting aid.

## Implementation Approach

Use Accessibility hit testing on mouse movement to find the window under the pointer and read its frame. Use a border-only floating `NSWindow` to draw the highlight. Keep this separate from process resolution so the existing click-to-target path remains authoritative.

## Components

### Highlight Target

Add a small value type that represents the visual target:

- Window frame in AppKit screen coordinates.
- Optional process name and PID when available.

### Accessibility Hover Hit Testing

Add an Accessibility helper for hover feedback:

- Hit test the pointer location.
- Walk from child element to parent elements until a window-like element with a frame is found.
- Convert the Accessibility frame into AppKit screen coordinates for the overlay.
- Return nil when no targetable window is found.

Failures during hover should not terminate picker mode. They should hide the overlay and keep waiting.

### Highlight Overlay

Add a small AppKit overlay object:

- Border-only, transparent background.
- Floating level above normal app windows.
- Ignores mouse events.
- Can show, move, and hide.
- Cleans up when picker exits.

### Picker Integration

Extend `ClickPicker`:

- Add a mouse-move monitor.
- On move, update the overlay target.
- On select/cancel/timeout/failure, hide and release the overlay.

The selected click point remains the input to `AccessibilityHitTester.targetProcess(at:)`; hover state should not decide which process is killed.

## Testing Strategy

Automated tests remain focused on pure logic:

- Coordinate conversion for overlay frames.
- Accessibility frame extraction helpers where possible.
- Existing unit harness remains the test runner.

Manual verification:

- Hovering a window shows a red border around that window.
- Moving between windows moves the border.
- Moving outside targetable windows hides the border.
- `--dry-run` still reports the clicked target.
- Cancel and timeout remove the overlay.

## Non-Goals

- No two-step confirmation mode.
- No animated effects.
- No attempt to consume the click event; the current global-monitor behavior remains.

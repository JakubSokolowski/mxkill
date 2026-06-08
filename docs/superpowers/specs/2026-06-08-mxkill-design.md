# mxkill Design

## Goal

Build `mxkill`, a macOS command-line utility that behaves like Linux `xkill`: the user runs a command, clicks a visible window, and the utility terminates the process that owns that window.

The first version targets local interactive use on macOS. It should be small, native, and easy to install from source.

## Non-Goals

- No GUI app bundle in the first version.
- No menu bar app or background daemon.
- No process picker list in the first version.
- No attempt to bypass macOS privacy or security controls.
- No support for killing system-protected processes beyond what the invoking user is allowed to signal.

## User Experience

Running `mxkill` enters picker mode. The utility waits for a click, identifies the clicked window's owning application process, prints the target, and terminates it.

Default behavior:

```sh
mxkill
```

- Checks whether Accessibility permission is available.
- If permission is missing, prints instructions and exits non-zero.
- Captures the next mouse click.
- Left click selects a window.
- Escape or right click cancels and exits successfully without killing anything.
- Sends `SIGTERM` to the owning PID by default.
- Prints the process name, PID, and signal sent.

Flags:

```sh
mxkill --force
mxkill --dry-run
mxkill --timeout 10
mxkill --include-self
```

- `--force`: sends `SIGKILL` instead of `SIGTERM`.
- `--dry-run`: identifies and prints the target without sending a signal.
- `--timeout <seconds>`: exits if no click occurs within the requested time.
- `--include-self`: allows selecting the `mxkill` process if it is somehow under the pointer. By default, selecting itself is refused.

## Implementation Approach

Use Swift with AppKit, ApplicationServices, and Darwin APIs.

Primary reasons:

- AppKit can run the short-lived event loop needed to capture global mouse and keyboard events.
- ApplicationServices exposes Accessibility APIs for hit-testing UI elements under the pointer.
- Darwin exposes `kill(2)` for sending signals.
- Swift produces a native macOS binary without requiring Python, Ruby, or Node runtime dependencies.

## Components

### CLI Argument Parser

Small hand-written parser for the initial version. The supported flag set is narrow enough that adding Swift Argument Parser would add more packaging cost than value.

Responsibilities:

- Parse `--force`, `--dry-run`, `--timeout <seconds>`, and `--include-self`.
- Reject unknown flags with usage text.
- Reject invalid timeout values.

### Accessibility Permission Check

Uses `AXIsProcessTrustedWithOptions` without silently continuing if permission is unavailable.

Behavior:

- If permission is granted, continue.
- If permission is missing, print a short explanation telling the user to allow the terminal application under System Settings > Privacy & Security > Accessibility.
- Exit with a non-zero status.

The tool may optionally pass the prompt option so macOS opens the permission prompt. The printed instructions remain the source of truth because macOS permission prompts can be inconsistent depending on the invoking terminal and system state.

### Event Capture

Runs a short-lived AppKit event loop and installs monitors for:

- Left mouse down: select target.
- Right mouse down: cancel.
- Escape key: cancel.

The tool should avoid killing anything until a left-click target has been resolved successfully.

Cursor behavior:

- Attempt to use a crosshair cursor while in picker mode.
- If cursor styling is unreliable in a terminal-launched AppKit process, keep the behavior functional and document that the cursor may not visibly change.

### Window Hit Testing

On click:

1. Read the current pointer location.
2. Use Accessibility system-wide hit testing to get the UI element at that point.
3. Walk from that element to an owning application element where needed.
4. Resolve the owning PID using `AXUIElementGetPid`.
5. Resolve a user-facing process name from the PID.

If the click lands on a child control, the PID still belongs to the owning application process, so killing that PID is correct.

### Process Termination

Default signal:

- `SIGTERM`

Force signal:

- `SIGKILL`

Behavior:

- Refuse to kill PID `0` or negative PIDs.
- Refuse to kill the current process unless `--include-self` is set.
- In `--dry-run`, print the target and exit without signaling.
- On `kill` failure, print the system error and exit non-zero.

## Error Handling

Expected errors should be concise and actionable:

- Accessibility permission missing.
- No UI element found at click point.
- Could not resolve owning PID.
- Refused to kill self.
- Signal failed due to permission, missing process, or another system error.
- Timeout expired.

Cancellation through Escape or right click is not an error.

## Testing Strategy

Automated tests focus on pure logic:

- CLI parsing accepts supported flags.
- CLI parsing rejects invalid flags and timeout values.
- Signal selection uses `SIGTERM` by default and `SIGKILL` with `--force`.
- Safety checks reject invalid PIDs and self-kill attempts unless opted in.

Manual verification covers OS-integrated behavior:

- Permission-missing path prints instructions.
- Permission-granted path allows selecting a test app window.
- `--dry-run` identifies a target without killing it.
- Default mode terminates a disposable app.
- `--force` sends `SIGKILL`.
- Escape and right click cancel.
- Timeout exits without requiring a click.

## Packaging

Use Swift Package Manager:

```sh
swift build -c release
```

The binary target name is `mxkill`.

Initial install flow can be:

```sh
cp .build/release/mxkill /usr/local/bin/mxkill
```

Homebrew packaging is out of scope for the first version.

## Open Decisions

- Binary name: use `mxkill` unless changed before implementation.
- Cursor styling: best effort, functional click selection is required.
- Permission prompt: call the official Accessibility trust API with prompt enabled, while still printing manual instructions.

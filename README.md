# mxkill

[![CI](https://github.com/JakubSokolowski/mxkill/actions/workflows/ci.yml/badge.svg)](https://github.com/JakubSokolowski/mxkill/actions/workflows/ci.yml)

`mxkill` is a small macOS command-line tool inspired by Linux `xkill`.
Run it, click a window, and `mxkill` sends a signal to the process that owns that window.

While picking a window, `mxkill` highlights the window under the pointer and shows a destructive cursor marker.

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer
- Accessibility permission for the terminal app that runs `mxkill`

## Build And Test

```sh
make test
make build
```

## Install

```sh
make install
```

By default this installs `mxkill` to `~/.local/bin/mxkill`.
Make sure `~/.local/bin` is in your `PATH`.

To install elsewhere:

```sh
make install PREFIX=/usr/local
```

## Usage

```sh
mxkill
```

Then click the window whose owning process should receive `SIGTERM`.

Options:

```sh
mxkill --force          # send SIGKILL instead of SIGTERM
mxkill --dry-run        # print the target without sending a signal
mxkill --timeout 5      # cancel if no window is picked within 5 seconds
mxkill --include-self   # allow targeting mxkill itself
```

Right-click or press Escape to cancel.

## Uninstall

```sh
make uninstall
```

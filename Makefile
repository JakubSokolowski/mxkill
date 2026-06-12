PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
BINARY = mxkill

.PHONY: build test install uninstall clean

build:
	swift build -c release

test:
	swift run mxkillUnitTests

install: build
	install -d "$(BINDIR)"
	install -m 755 ".build/release/$(BINARY)" "$(BINDIR)/$(BINARY)"
	@printf 'Installed %s to %s/%s\n' "$(BINARY)" "$(BINDIR)" "$(BINARY)"

uninstall:
	rm -f "$(BINDIR)/$(BINARY)"
	@printf 'Removed %s/%s\n' "$(BINDIR)" "$(BINARY)"

clean:
	rm -rf .build

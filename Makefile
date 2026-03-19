CARGO    := $(HOME)/.cargo/bin/cargo
TMPL_DIR := $(CURDIR)/template

.PHONY: all build uf2 clean

all: uf2

## Step 1 — compile firmware
build:
	cd $(TMPL_DIR) && $(CARGO) build --release

## Step 2 — ELF → Intel HEX → UF2, copy artifacts to repo root
uf2: build
	$(CARGO) install cargo-make --quiet
	cd $(TMPL_DIR) && $(CARGO) make uf2 --release
	cp $(TMPL_DIR)/*.uf2 $(CURDIR)/
	@echo ""
	@echo "✓  central.uf2    — drag onto left  Nice Nano in bootloader mode"
	@echo "✓  peripheral.uf2 — drag onto right Nice Nano in bootloader mode"

clean:
	cd $(TMPL_DIR) && $(CARGO) clean
	rm -f $(TMPL_DIR)/*.uf2 $(TMPL_DIR)/*.hex
	rm -f $(CURDIR)/*.uf2

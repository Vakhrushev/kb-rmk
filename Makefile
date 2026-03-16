BUILD_DIR := $(CURDIR)/build
CARGO     := $(HOME)/.cargo/bin/cargo
RMKIT     := $(HOME)/.cargo/bin/rmkit

.PHONY: all generate build uf2 clean

all: uf2

## Step 1 — generate Rust project from keyboard.toml + vial.json
generate:
	$(RMKIT) create \
		--keyboard-toml-path keyboard.toml \
		--vial-json-path vial.json \
		--target-dir $(BUILD_DIR)

## Step 2 — compile firmware
build: generate
	cd $(BUILD_DIR) && $(CARGO) build --release

## Step 3 — ELF → Intel HEX → UF2  (same pipeline as CI)
uf2: build
	$(CARGO) install cargo-make --quiet
	cd $(BUILD_DIR) && $(CARGO) make uf2 --release
	cp $(BUILD_DIR)/*-central.uf2   $(CURDIR)/central.uf2
	cp $(BUILD_DIR)/*-peripheral.uf2 $(CURDIR)/peripheral.uf2
	@echo ""
	@echo "✓  central.uf2    — drag onto left  Nice Nano in bootloader mode"
	@echo "✓  peripheral.uf2 — drag onto right Nice Nano in bootloader mode"

clean:
	rm -rf $(BUILD_DIR) central.uf2 peripheral.uf2

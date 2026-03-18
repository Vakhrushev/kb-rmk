BUILD_DIR    := $(CURDIR)/build
CARGO        := $(HOME)/.cargo/bin/cargo
RMKIT        := $(HOME)/.cargo/bin/rmkit
RMKIT_CLONE  := /tmp/rmkit-patched

.PHONY: all install-rmkit generate build uf2 clean

all: uf2

## Step 0 — install rmkit with rmk-config from main branch (needed for report_hz, spi.instance)
##   Upstream rmkit pins rmk-config to crates.io which lacks unreleased fields,
##   so we clone rmkit, patch Cargo.toml to use rmk-config from git, and install.
install-rmkit:
	@if [ ! -d "$(RMKIT_CLONE)" ]; then \
		git clone --depth 1 https://github.com/HaoboGu/rmkit.git $(RMKIT_CLONE); \
		sed -i '' 's|rmk-config = { version = "0.6.0" }|rmk-config = { git = "https://github.com/HaoboGu/rmk", branch = "main" }|' $(RMKIT_CLONE)/Cargo.toml; \
	fi
	$(CARGO) install --path $(RMKIT_CLONE) --force

## Step 1 — generate Rust project from keyboard.toml + vial.json
generate: install-rmkit
	$(RMKIT) create \
		--keyboard-toml-path keyboard.toml \
		--vial-json-path vial.json \
		--version main \
		--target-dir $(BUILD_DIR)

## Step 1.5 — patch generated Cargo.toml to use deps from rmk main branch
##   rmkit generates crates.io versions that are behind main (embassy-nrf 0.8 vs 0.9,
##   bt-hci 0.6 vs 0.8, old nrf-sdc/nrf-mpsl rev). Patch all of them.
NRF_SDC_REV := 43df6b8b0affeacd9cb4094a3ab4f81576554887
patch-deps: generate
	sed -i '' \
		-e 's|rmk = { version = "0.8"|rmk = { git = "https://github.com/HaoboGu/rmk", branch = "main"|' \
		-e 's|embassy-nrf = { version = "0.8"|embassy-nrf = { version = "0.9"|' \
		-e 's|bt-hci = { version = "0.6"|bt-hci = { version = "0.8"|' \
		-e 's|rev = "11d5c3c"|rev = "$(NRF_SDC_REV)"|g' \
		$(BUILD_DIR)/Cargo.toml

## Step 2 — compile firmware
build: patch-deps
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

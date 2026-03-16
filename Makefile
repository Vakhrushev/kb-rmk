BUILD_DIR     := $(CURDIR)/build
OBJCOPY       := $(HOME)/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/aarch64-apple-darwin/bin/llvm-objcopy
UF2CONV       := $(CURDIR)/tools/uf2conv.py
UF2FAMILIES   := $(CURDIR)/tools/uf2families.json
CARGO         := $(HOME)/.cargo/bin/cargo
RMKIT         := $(HOME)/.cargo/bin/rmkit
NRF_FAMILY    := 0xADA52840
FLASH_BASE    := 0x27000

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

## Step 3 — convert ELF → bin → UF2
uf2: build
	@$(OBJCOPY) -O binary \
		$(BUILD_DIR)/target/thumbv7em-none-eabihf/release/central \
		$(BUILD_DIR)/central.bin
	@$(OBJCOPY) -O binary \
		$(BUILD_DIR)/target/thumbv7em-none-eabihf/release/peripheral \
		$(BUILD_DIR)/peripheral.bin
	@# Download helpers if missing
	@mkdir -p $(dir $(UF2CONV))
	@[ -f $(UF2CONV) ] || curl -sL \
		https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2conv.py \
		-o $(UF2CONV)
	@[ -f $(UF2FAMILIES) ] || curl -sL \
		https://raw.githubusercontent.com/microsoft/uf2/master/utils/uf2families.json \
		-o $(UF2FAMILIES)
	python3 $(UF2CONV) $(BUILD_DIR)/central.bin \
		--base $(FLASH_BASE) --family $(NRF_FAMILY) --output central.uf2
	python3 $(UF2CONV) $(BUILD_DIR)/peripheral.bin \
		--base $(FLASH_BASE) --family $(NRF_FAMILY) --output peripheral.uf2
	@echo ""
	@echo "✓  central.uf2   — drag onto left  Nice Nano in bootloader mode"
	@echo "✓  peripheral.uf2 — drag onto right Nice Nano in bootloader mode"

clean:
	rm -rf $(BUILD_DIR) central.uf2 peripheral.uf2

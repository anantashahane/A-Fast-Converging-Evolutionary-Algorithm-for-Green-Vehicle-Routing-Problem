# ---------- CONFIG ----------
TARGET = heso_vrp
BASE = Source/base/*.swift
MAIN = Source/main.swift

# Get all Swift files except main.swift
EXTRA_SRCS := $(filter-out Source/main.swift, $(wildcard Source/*.swift))
OPTIONS := $(notdir $(basename $(EXTRA_SRCS)))

# Default build
ALG ?= none

# ---------- HELP ----------
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make ALG=<option> build"
	@echo ""
	@echo "Available options:"
	@$(foreach opt,$(OPTIONS), echo "  - $(opt)";)
	@echo ""
	@echo "Example:"
	@echo "  make ALG=A build"

# ---------- BUILD ----------
.PHONY: all
all: build

.PHONY: build
build:
ifeq ($(ALG),none)
	@echo "No ALG selected. Run 'make help'"
	@exit 1
endif

	@echo "Building with ALG=$(ALG)"

	@if [ -f Source/$(ALG).swift ]; then \
		swiftc -O $(BASE) Source/$(ALG).swift $(MAIN) -o $(TARGET); \
	else \
		echo "Invalid option: $(ALG)"; \
		exit 1; \
	fi
# Forensic OS - Build System Makefile
# Usage: make [target]
#   make build   - Build the forensic ISO image
#   make clean   - Clean the build environment
#   make rebuild - Clean and rebuild from scratch
#   make usb     - Write ISO to USB device
#   make setup   - Install build dependencies
#   make help    - Show this help message

SHELL := /bin/bash
.DEFAULT_GOAL := help

LIVEBUILD_DIR := config/live-build
SCRIPTS_DIR := scripts
ISO_FILE := $(shell find $(LIVEBUILD_DIR) -maxdepth 1 -name "*.iso" -type f 2>/dev/null | head -1)

# Colors
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
CYAN   := \033[0;36m
NC     := \033[0m

.PHONY: build clean rebuild usb setup test lint help

## Build the Forensic OS ISO image
build:
	@echo -e "$(GREEN)[*] Building Forensic OS ISO...$(NC)"
	@$(SCRIPTS_DIR)/build-iso.sh

## Clean the build environment
clean:
	@echo -e "$(YELLOW)[*] Cleaning build environment...$(NC)"
	@cd $(LIVEBUILD_DIR) && lb clean --purge 2>/dev/null || true
	@rm -f $(LIVEBUILD_DIR)/*.iso $(LIVEBUILD_DIR)/*.zsync $(LIVEBUILD_DIR)/build.log
	@echo -e "$(GREEN)[*] Clean complete.$(NC)"

## Clean and rebuild from scratch
rebuild: clean build

## Write ISO to USB device (interactive - will prompt for device)
usb:
	@if [ -z "$(ISO_FILE)" ]; then \
		echo -e "$(RED)[!] No ISO file found. Run 'make build' first.$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(CYAN)[*] Writing ISO to USB...$(NC)"
	@$(SCRIPTS_DIR)/write-usb.sh "$(ISO_FILE)"

## Install build dependencies (requires root)
setup:
	@echo -e "$(CYAN)[*] Setting up development environment...$(NC)"
	@$(SCRIPTS_DIR)/setup-dev.sh

## Run the test suite
test:
	@echo -e "$(CYAN)[*] Running ForensicOS test suite...$(NC)"
	@bash tests/run-all-tests.sh

## Lint all shell scripts with shellcheck
lint:
	@echo -e "$(CYAN)[*] Linting shell scripts...$(NC)"
	@FAIL=0; \
	for f in tools/* lib/*.sh ui/forensic-* scripts/*.sh tests/test-*.sh; do \
		if [ -f "$$f" ] && head -1 "$$f" | grep -q 'bash\|sh'; then \
			echo "  Checking: $$f"; \
			shellcheck -x "$$f" 2>/dev/null || FAIL=1; \
		fi; \
	done; \
	if [ $$FAIL -eq 0 ]; then \
		echo -e "$(GREEN)[*] All scripts pass lint.$(NC)"; \
	else \
		echo -e "$(YELLOW)[!] Some scripts have lint warnings.$(NC)"; \
	fi

## Show help
help:
	@echo ""
	@echo -e "$(CYAN)Forensic OS Build System$(NC)"
	@echo -e "$(CYAN)========================$(NC)"
	@echo ""
	@echo -e "  $(GREEN)make build$(NC)    - Build the forensic ISO image"
	@echo -e "  $(GREEN)make clean$(NC)    - Clean the build environment"
	@echo -e "  $(GREEN)make rebuild$(NC)  - Clean and rebuild from scratch"
	@echo -e "  $(GREEN)make usb$(NC)      - Write ISO to USB device (interactive)"
	@echo -e "  $(GREEN)make test$(NC)     - Run the test suite"
	@echo -e "  $(GREEN)make lint$(NC)     - Lint shell scripts with shellcheck"
	@echo -e "  $(GREEN)make setup$(NC)    - Install build dependencies"
	@echo -e "  $(GREEN)make help$(NC)     - Show this help message"
	@echo ""
	@echo -e "$(YELLOW)Prerequisites:$(NC)"
	@echo -e "  Run '$(CYAN)make setup$(NC)' first to install live-build and dependencies."
	@echo -e "  Then '$(CYAN)make build$(NC)' to create the ISO."
	@echo ""

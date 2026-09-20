#### Start of standard makefile configuration. ####

SHELL := /usr/bin/env bash
LN_S := ln -sf

# Root of the installation
prefix := /usr/local

# Root of the executables
exec_prefix := $(prefix)

# Executables
bindir := $(exec_prefix)/bin

# Enable delete on error, which is disabled by default for legacy reasons
.DELETE_ON_ERROR:

#### End of standard makefile configuration. ####

# Project specific absolute path (readlink resolves the symlinked per-app
# Makefile so filters/templates are located from any application folder)
srcdir := $(shell dirname "$$(readlink -f "$(lastword $(MAKEFILE_LIST))")")

green := \\e[32m
blue := \\e[34m
bold := \\e[1m
reset := \\e[0m

.PHONY: all
all: build

FILTER := $(srcdir)/filters/resume.lua
TEMPLATE := $(srcdir)/templates/resume.ms
PANDOC := pandoc --lua-filter=$(FILTER) --template=$(TEMPLATE) -s

PANDOC_MIN_VERSION := 3.5

.PHONY: check-deps
check-deps:
	@have="$$(pandoc --version 2>/dev/null | head -n 1 | awk '{print $$2}')"; \
	if [ -z "$$have" ]; then echo "roffume: pandoc not found (need >= $(PANDOC_MIN_VERSION))" >&2; exit 1; fi; \
	awk -v have="$$have" -v min="$(PANDOC_MIN_VERSION)" 'BEGIN { n = split(have, h, "\\."); m = split(min, t, "\\."); for (i = 1; i <= (n > m ? n : m); i++) { a = (i <= n ? h[i] : 0) + 0; b = (i <= m ? t[i] : 0) + 0; if (a > b) exit 0; if (a < b) exit 1; } exit 0; }' \
	|| { echo "roffume: pandoc $$have too old (need >= $(PANDOC_MIN_VERSION))" >&2; exit 1; }

# Resume sources: resume.md is the canonical (English) source; any extra
# resume_<language>.md lives alongside it. The glob never matches resume.md
# itself (it requires the underscore), so list it explicitly.
SOURCES := resume.md $(wildcard resume_*.md)

# Fixed timestamp for reproducible PDF output. gropdf reads SOURCE_DATE_EPOCH
# as the PDF CreationDate; a constant keeps rebuilds byte-identical so the
# committed renamed PDFs don't churn in git when nothing changed. A zero value
# is treated as "unset" (PDF can't represent the Unix epoch), so use a real
# fixed date. 315532800 = 1980-01-01 00:00:00 UTC, the earliest date the
# FAT/zip family of formats can represent.
SOURCE_DATE_EPOCH := 315532800

.PHONY: build
build: check-deps
	@echo -e $(blue)Building PDF ...$(reset)
	@for src in $(SOURCES); do \
	  base=$${src%.md}; \
	  $(PANDOC) $$src -o $$base.ms; \
	  echo -e '   'Building $(green)$$base.pdf$(reset) from $(green)$$base.ms$(reset); \
	  SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $$(grog -U -b -ww -k -Tpdf $$base.ms) >| $$base.pdf; \
	done
	@echo -e $(blue)Building PDF$(reset) $(green)DONE$(reset)

# Fixed location for the `make preview` PDF (rendered, then opened in the
# platform's default viewer).
PREVIEW_PDF := /tmp/roffume-preview.pdf

.PHONY: preview
preview: check-deps
	@$(PANDOC) resume.md -o resume.ms
	@SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) $$(grog -U -b -ww -k -Tpdf resume.ms) >| $(PREVIEW_PDF)
	@if [ "$$(uname)" = "Darwin" ]; then open $(PREVIEW_PDF); else xdg-open $(PREVIEW_PDF); fi &
	@echo -e $(blue)Previewing PDF$(reset) $(green)DONE$(reset)

.PHONY: clean
clean:
	@echo -e $(blue)Cleaning generated outputs ...$(reset)
	@rm -f resume*.ms resume*.pdf
	@echo -e $(blue)Clean$(reset) $(green)DONE$(reset)


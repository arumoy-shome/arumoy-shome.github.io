# arumoy.me — pandoc + make. `make` builds _site, `make serve` previews it.

PANDOC ?= pandoc
SITE   := _site
BUILD  := build

POSTS     := $(wildcard blogs/*/index.md)
POST_HTML := $(patsubst blogs/%/index.md,$(SITE)/blogs/%/index.html,$(POSTS))
ASSETS    := $(shell find blogs -type f ! -name '*.md')
ASSET_OUT := $(patsubst blogs/%,$(SITE)/blogs/%,$(ASSETS))
PAGES     := pages/index.md pages/license.md pages/resume.md \
             pages/publications.md
PAGE_HTML := $(patsubst pages/%.md,$(SITE)/%.html,$(PAGES))

STATIC := $(SITE)/styles.css $(SITE)/profile.jpeg $(SITE)/CNAME $(SITE)/robots.txt
GENPAGE := $(SITE)/blogs.html $(SITE)/talks.html \
           $(SITE)/blogs/tags/index.html
GENXML  := $(SITE)/blogs.xml $(SITE)/sitemap.xml

# The template pulls nav, footer and og: metadata out of site.yaml.
# --citeproc is harmless on documents without citations, so it lives here.
# --wrap=none keeps pandoc's HTML writer from folding long lines, which
# otherwise injects newlines inside <title> and <meta content="…"> values.
CSL := association-for-computing-machinery.csl

COMMON := --standalone --wrap=none \
          --template=templates/page.html \
          --metadata-file=site.yaml \
          --citeproc --bibliography=bibliography.bib --csl=$(CSL) \
          --metadata reference-section-title="References"
POST_FLAGS := $(COMMON) --toc --metadata author="Arumoy Shome"

# The inputs every pandoc call reads, and therefore the prerequisites every
# HTML output shares. bibliography.bib and the CSL belong here because
# --citeproc runs on every page: without them, editing a reference or the
# citation style rebuilds nothing.
COMMON_DEPS := templates/page.html site.yaml bibliography.bib $(CSL)

.PHONY: all clean serve tags test
all: $(PAGE_HTML) $(POST_HTML) $(ASSET_OUT) $(GENPAGE) $(GENXML) $(STATIC) tags

# tests/run builds first anyway; depending on all here keeps `make test` in a
# clean tree from looking like a test failure. TEST_FAST=1 skips 40-42, which
# do full rebuilds and account for most of the runtime.
test: all
	tests/run

# --- generated data ------------------------------------------------------
# bin/index writes build/{blogs.md,blogs.xml,sitemap.xml,tags/*.md} in one
# pass over the posts; blogs.md is the stamp for all of them.
$(BUILD)/blogs.md: $(POSTS) bin/index templates/listing.md \
                   templates/meta.txt templates/feed-item.xml \
                   pages/blogs-intro.md pages/tags-intro.md site.yaml \
                   bibliography.bib $(CSL)
	@mkdir -p $(BUILD)
	bin/index

$(BUILD)/talks.md: talks.yaml templates/talks.md pages/talks-intro.md bin/yamlseq
	@mkdir -p $(BUILD)
	bin/yamlseq talks talks.yaml > $(BUILD)/talks-data.yaml
	cp pages/talks-intro.md $@
	@printf '\n' >> $@
	$(PANDOC) /dev/null -f markdown -t markdown --wrap=none \
	  --template=templates/talks.md \
	  --metadata-file=$(BUILD)/talks-data.yaml >> $@

# --- html ----------------------------------------------------------------
$(SITE)/blogs/%/index.html: blogs/%/index.md $(COMMON_DEPS) $(BUILD)/blogs.md
	@mkdir -p $(dir $@)
	$(PANDOC) $(POST_FLAGS) --metadata-file=$(BUILD)/meta/$*.yaml -o $@ $<

$(SITE)/%.html: pages/%.md $(COMMON_DEPS)
	@mkdir -p $(dir $@)
	$(PANDOC) $(COMMON) -o $@ $<

$(SITE)/%.html: $(BUILD)/%.md $(COMMON_DEPS)
	@mkdir -p $(dir $@)
	$(PANDOC) $(COMMON) -o $@ $<

# The tag index lives at /blogs/tags/, so neither pattern rule above matches
# it: the post rule would want blogs/tags/index.md, the generated-page rule
# build/blogs/tags/index.md. build/blogs.md is the stamp for everything
# bin/index writes, build/tags.md included.
$(SITE)/blogs/tags/index.html: $(BUILD)/blogs.md $(COMMON_DEPS)
	@mkdir -p $(dir $@)
	$(PANDOC) $(COMMON) -o $@ $(BUILD)/tags.md

# Category pages are discovered only after bin/index has run, so they are
# built by a recursive make rather than by a static pattern rule.
tags: $(BUILD)/blogs.md
	@mkdir -p $(SITE)/blogs/tags
	@for f in $(BUILD)/tags/*.md; do \
	  out=$(SITE)/blogs/tags/$$(basename $$f .md).html; \
	  $(PANDOC) $(COMMON) -o $$out $$f; \
	done

# --- copied artefacts ----------------------------------------------------
$(SITE)/blogs/%: blogs/%
	@mkdir -p $(dir $@)
	cp $< $@

$(SITE)/blogs.xml: $(BUILD)/blogs.md
	@mkdir -p $(SITE)
	cp $(BUILD)/blogs.xml $@

$(SITE)/sitemap.xml: $(BUILD)/blogs.md
	@mkdir -p $(SITE)
	cp $(BUILD)/sitemap.xml $@

$(SITE)/styles.css: styles.css
	@mkdir -p $(SITE)
	cp $< $@

$(SITE)/profile.jpeg: profile.jpeg
	@mkdir -p $(SITE)
	cp $< $@

$(SITE)/CNAME: CNAME
	@mkdir -p $(SITE)
	cp $< $@

$(SITE)/robots.txt: robots.txt
	@mkdir -p $(SITE)
	cp $< $@

clean:
	rm -rf $(SITE) $(BUILD)

serve: all
	bin/serve

# arumoy.me — pandoc + make. `make` builds _site, `make serve` previews it.

PANDOC ?= pandoc
SITE   := _site
BUILD  := build

POSTS     := $(wildcard blogs/*/index.md)
POST_HTML := $(patsubst blogs/%/index.md,$(SITE)/blogs/%/index.html,$(POSTS))
ASSETS    := $(shell find blogs -type f ! -name '*.md')
ASSET_OUT := $(patsubst blogs/%,$(SITE)/blogs/%,$(ASSETS))
PAGES     := pages/index.md pages/license.md pages/resume.md
PAGE_HTML := $(patsubst pages/%.md,$(SITE)/%.html,$(PAGES))

STATIC := $(SITE)/styles.css $(SITE)/profile.jpeg $(SITE)/CNAME $(SITE)/robots.txt
GENPAGE := $(SITE)/blogs.html $(SITE)/talks.html $(SITE)/publications.html
GENXML  := $(SITE)/blogs.xml $(SITE)/sitemap.xml

# The template pulls nav, footer and og: metadata out of site.yaml.
# --citeproc is harmless on documents without citations, so it lives here.
# --wrap=none keeps pandoc's HTML writer from folding long lines, which
# otherwise injects newlines inside <title> and <meta content="…"> values.
COMMON := --standalone --wrap=none \
          --template=templates/page.html \
          --metadata-file=site.yaml \
          --citeproc --bibliography=bibliography.bib \
          --metadata reference-section-title="References"
POST_FLAGS := $(COMMON) --toc --metadata author="Arumoy Shome"

# The inputs every pandoc call reads, and therefore the prerequisites every
# HTML output shares. bibliography.bib belongs here because --citeproc runs on
# every page: without it, editing a reference rebuilds nothing.
COMMON_DEPS := templates/page.html site.yaml bibliography.bib

.PHONY: all clean serve tags
all: $(PAGE_HTML) $(POST_HTML) $(ASSET_OUT) $(GENPAGE) $(GENXML) $(STATIC) tags

# --- generated data ------------------------------------------------------
# bin/index writes build/{blogs.md,blogs.xml,sitemap.xml,tags/*.md} in one
# pass over the posts; blogs.md is the stamp for all of them.
$(BUILD)/blogs.md: $(POSTS) bin/index templates/listing.md \
                   templates/meta.txt templates/feed-item.xml \
                   pages/blogs-intro.md site.yaml bibliography.bib
	@mkdir -p $(BUILD)
	bin/index

$(BUILD)/publications.md: publications.yaml templates/publications.md \
                          pages/publications-intro.md bin/yamlseq
	@mkdir -p $(BUILD)
	bin/yamlseq publications publications.yaml > $(BUILD)/publications-data.yaml
	cp pages/publications-intro.md $@
	@printf '\n' >> $@
	$(PANDOC) /dev/null -f markdown -t markdown --wrap=none \
	  --template=templates/publications.md \
	  --metadata-file=$(BUILD)/publications-data.yaml >> $@

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

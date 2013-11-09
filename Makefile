PONIES=	applejack-nohat \
	fluttershy \
	pinkie-pie \
	rainbow-dash \
	rarity \
	twilight-alicorn \
	twilight-unicorn \
	derpy \
	trixie-hat \
	rose \
	lyra

MAKEFILE_DIR=$(dir $(lastword $(MAKEFILE_LIST)))
PONY_DIR=$(MAKEFILE_DIR)Ponies
SCRIPT=$(MAKEFILE_DIR)render_parts.php
OUT_DIR=$(MAKEFILE_DIR)rendered
OUT_PLAIN=$(addprefix $(PONY_DIR)/,$(addsuffix .txt,$(PONIES)))
OUT_COLOR=$(addprefix $(OUT_DIR)/,$(addsuffix .colored.txt,$(PONIES)))
OUT_SVG=$(addprefix $(OUT_DIR)/,$(addsuffix .svg,$(PONIES)))
OUT_PNG=$(addprefix $(OUT_DIR)/,$(addsuffix .png,$(PONIES)))
OUT_BASH=$(addprefix $(OUT_DIR)/,$(addsuffix .sh,$(PONIES)))
OUT_ALL= $(OUT_COLOR) $(OUT_PLAIN) $(OUT_SVG) $(OUT_PNG) $(OUT_BASH)
OUT_DIRS=$(sort $(dir $(OUT_ALL)))
find_deps=$(addprefix $(PONY_DIR)/,$(subst ;,\\\;,$(wildcard $(1)/*)))

.PHONY: show show_deps cleans

all: $(OUT_ALL)

define rule_template
$(OUT_DIR)/$(1).colored.txt: | $(dir $(OUT_DIR)/$(1))
$(OUT_DIR)/$(1).colored.txt: $(call find_deps, $(1))
$(OUT_DIR)/$(1).colored.txt:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/$(1).colored.txt

$(PONY_DIR)/$(1).txt: $(call find_deps, $(1))
$(PONY_DIR)/$(1).txt:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(PONY_DIR)/$(1).txt nocolor
	
$(OUT_DIR)/$(1).svg: | $(dir $(OUT_DIR)/$(1))
$(OUT_DIR)/$(1).svg: $(call find_deps, $(1))
$(OUT_DIR)/$(1).svg:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/$(1).svg svg
	
$(OUT_DIR)/$(1).sh: | $(dir $(OUT_DIR)/$(1))
$(OUT_DIR)/$(1).sh: $(call find_deps, $(1))
$(OUT_DIR)/$(1).sh:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/$(1).sh bash
	chmod a+x $(OUT_DIR)/$(1).sh
endef
define dir_rule_template
$(1) : 
	mkdir -p $(1)
endef

%.png : %.svg
	inkscape $*.svg -e $*.png

$(foreach pony,$(PONIES),$(eval $(call rule_template,$(pony))))
$(foreach directory,$(OUT_DIRS),$(eval $(call dir_rule_template,$(directory))))

show: $(OUT_DIR)/$(PONY).colored.txt
	@cat $(OUT_DIR)/$(PONY).colored.txt
	
show_deps:
	@$(foreach d,$(call find_deps,$(PONY)), echo $(d);)
	
clean:
	rm -f $(OUT_ALL)
	rmdir --ignore-fail-on-non-empty $(OUT_DIRS) $(OUT_DIR)

PONIES=	Main6/applejack-nohat \
	Main6/fluttershy \
	Main6/pinkie-pie \
	Main6/rainbow-dash \
	Main6/rarity \
	Main6/twilight-alicorn \
	Main6/twilight-unicorn \
	Other/derpy \
	Other/trixie-hat 

	

SCRIPT=$(PWD)/render_parts.php
OUT_DIR=rendered
OUT_PLAIN=$(addsuffix .txt,$(PONIES))
OUT_COLOR=$(addprefix $(OUT_DIR)/,$(addsuffix .colored.txt,$(PONIES)))
OUT_SVG=$(addprefix $(OUT_DIR)/,$(addsuffix .svg,$(PONIES)))
OUT_PNG=$(addprefix $(OUT_DIR)/,$(addsuffix .png,$(PONIES)))
OUT_ALL= $(OUT_COLOR) $(OUT_PLAIN) $(OUT_SVG) $(OUT_PNG)
OUT_DIRS=$(sort $(dir $(OUT_ALL)))
find_deps=$(subst ;,\\\;,$(wildcard $(1)/*))

all: $(OUT_ALL)

define rule_template
$(OUT_DIR)/$(1).colored.txt: $(dir $(OUT_DIR)/$(1))
$(OUT_DIR)/$(1).colored.txt: $(call find_deps, $(1))
	$(SCRIPT) $(1) >$(OUT_DIR)/$(1).colored.txt

$(1).txt: $(call find_deps, $(1))
	$(SCRIPT) $(1) >$(1).txt nocolor
	
$(OUT_DIR)/$(1).svg: $(dir $(OUT_DIR)/$(1))
$(OUT_DIR)/$(1).svg: $(call find_deps, $(1))
	$(SCRIPT) $(1) >$(OUT_DIR)/$(1).svg svg
endef
define dir_rule_template
$(1) : 
	mkdir -p $(1)
endef

%.png : %.svg
	inkscape $*.svg -e $*.png

$(foreach pony,$(PONIES),$(eval $(call rule_template,$(pony))))
$(foreach directory,$(OUT_DIRS),$(eval $(call dir_rule_template,$(directory))))

show: $(PONY).colored.txt
	@cat $(PONY).colored.txt
	
show_deps:
	@$(foreach d,$(call find_deps,$(PONY)), echo $(d);)
	
clean:
	rm -f $(OUT_ALL)
	rmdir --ignore-fail-on-non-empty $(OUT_DIRS) $(OUT_DIR)

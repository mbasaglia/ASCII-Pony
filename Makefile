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
OUT_PLAIN=$(addsuffix .plain.txt,$(PONIES))
OUT_COLOR=$(addsuffix .colored.txt,$(PONIES))
find_deps=$(subst ;,\\\;,$(wildcard $(1)/*))

all: $(OUT_COLOR) $(OUT_PLAIN)

define rule_template
$(1).colored.txt: $(call find_deps, $(1))
	$(SCRIPT) $(1) >$(1).colored.txt

$(1).plain.txt: $(call find_deps, $(1))
	$(SCRIPT) $(1) >$(1).plain.txt nocolor
endef

$(foreach pony,$(PONIES),$(eval $(call rule_template,$(pony))))

show: $(PONY).colored.txt
	@cat $(PONY).colored.txt
	
show_deps:
	@$(foreach d,$(call find_deps,$(PONY)), echo $(d);)
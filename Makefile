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
find_deps=$(subst ;,\;,$(wildcard $(1)/*))

.PHONY: show

all: $(OUT_COLOR) $(OUT_PLAIN)


# %.colored.txt : $(SCRIPT)
# %.colored.txt : $(PWD)/Makefile
%.colored.txt : $(call find_deps, $*)
	 $(SCRIPT) $* >$*.colored.txt

# %.plain.txt : $(SCRIPT)
# %.plain.txt : $(PWD)/Makefile
%.plain.txt : $(call find_deps, $*)
	$(SCRIPT) $* >$*.plain.txt nocolor

show: $(PONY).colored.txt
	@cat $(PONY).colored.txt
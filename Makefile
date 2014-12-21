PREFIX?=/usr/local
DATAROOT=$(PREFIX)/share
DATADIR=$(DATAROOT)/ascii-pony
BINDIR=$(PREFIX)/bin

MAKEFILE=$(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR=$(dir $(MAKEFILE))
PONY_DIR=$(MAKEFILE_DIR)Ponies
SCRIPT=$(MAKEFILE_DIR)render_parts.php
OUT_DIR=$(MAKEFILE_DIR)rendered
PONIES=$(notdir $(shell find $(PONY_DIR) -maxdepth 1 -mindepth 1 -type d ))
OUT_PLAIN=$(addprefix $(PONY_DIR)/,$(addsuffix .txt,$(PONIES)))
OUT_COLOR=$(addprefix $(OUT_DIR)/ansi/,$(addsuffix .colored.txt,$(PONIES)))
OUT_COLOR_IRC=$(addprefix $(OUT_DIR)/irc/,$(addsuffix .irc.txt,$(PONIES)))
OUT_SVG=$(addprefix $(OUT_DIR)/svg/,$(addsuffix .svg,$(PONIES)))
OUT_PNG=$(addprefix $(OUT_DIR)/png/,$(addsuffix .png,$(PONIES)))
OUT_BASH=$(addprefix $(OUT_DIR)/sh/,$(addsuffix .sh,$(PONIES)))
OUT_ALL= $(OUT_COLOR) $(OUT_PLAIN) $(OUT_SVG) $(OUT_PNG) $(OUT_BASH) $(OUT_COLOR_IRC)
OUT_DIRS=$(sort $(dir $(OUT_ALL)))
find_deps=$(subst ;,\\\;,$(wildcard $(PONY_DIR)/$(1)/*))

INSTALL_DIR=cp -rf
INSTALL_FILE=cp -f
UNINSTALL_DIR=rm -rf
UNINSTALL_FILE=rm -f
REMOVE_DIR=$(foreach d, $(1), [ -d $(d) ] && rmdir $(d) || true;)
MAKE_DIR=mkdir -p

# NOTE: not .PONY :-P
.PHONY: all show show_deps clean list random install uninstall

all: $(OUT_ALL)

define rule_template
$(OUT_DIR)/ansi/$(1).colored.txt: | $(dir $(OUT_DIR)/ansi/$(1))
$(OUT_DIR)/ansi/$(1).colored.txt: $(call find_deps, $(1))
$(OUT_DIR)/ansi/$(1).colored.txt:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/ansi/$(1).colored.txt

$(PONY_DIR)/$(1).txt: $(call find_deps, $(1))
$(PONY_DIR)/$(1).txt:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(PONY_DIR)/$(1).txt nocolor
	
$(OUT_DIR)/svg/$(1).svg: | $(dir $(OUT_DIR)/svg/$(1))
$(OUT_DIR)/svg/$(1).svg: $(call find_deps, $(1))
$(OUT_DIR)/svg/$(1).svg:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/svg/$(1).svg svg
	
$(OUT_DIR)/sh/$(1).sh: | $(dir $(OUT_DIR)/sh/$(1))
$(OUT_DIR)/sh/$(1).sh: $(call find_deps, $(1))
$(OUT_DIR)/sh/$(1).sh:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/sh/$(1).sh bash
	chmod a+x $(OUT_DIR)/sh/$(1).sh
	
	
$(OUT_DIR)/irc/$(1).irc.txt: | $(dir $(OUT_DIR)/irc/$(1))
$(OUT_DIR)/irc/$(1).irc.txt: $(call find_deps, $(1))
$(OUT_DIR)/irc/$(1).irc.txt:  $(PONY_DIR)/$(1)
	$(SCRIPT) $(PONY_DIR)/$(1) >$(OUT_DIR)/irc/$(1).irc.txt irc

$(OUT_DIR)/png/$(1).png :  $(dir $(OUT_DIR)/png/$(1))
$(OUT_DIR)/png/$(1).png : $(OUT_DIR)/svg/$(1).svg
	inkscape $(OUT_DIR)/svg/$(1).svg -e $(OUT_DIR)/png/$(1).png

.PHONY: $(1)
$(1) : $(OUT_DIR)/ansi/$(1).colored.txt
$(1) : $(PONY_DIR)/$(1).txt
$(1) : $(OUT_DIR)/svg/$(1).svg
$(1) : $(OUT_DIR)/sh/$(1).sh
$(1) : $(OUT_DIR)/irc/$(1).irc.txt
$(1) : $(OUT_DIR)/png/$(1).png
	@cat $(OUT_DIR)/ansi/$(1).colored.txt

endef
define dir_rule_template
$(1) : 
	$(MAKE_DIR) $(1)
endef

$(foreach pony,$(PONIES),$(eval $(call rule_template,$(pony))))
$(foreach directory,$(OUT_DIRS),$(eval $(call dir_rule_template,$(directory))))

show: $(OUT_DIR)/ansi/$(PONY).colored.txt
	@cat $(OUT_DIR)/ansi/$(PONY).colored.txt
	
show_deps:
	@$(foreach d,$(call find_deps,$(PONY)), echo $(d);)
	
clean:
	$(REMOVE_FILE) $(OUT_ALL)
	$(call REMOVE_DIR, $(OUT_DIRS) $(OUT_DIR))

list:
	@$(foreach pony,$(PONIES), echo $(pony);)
	
random: PONY=$(shell make -f $(MAKEFILE) list | shuf | head -n 1)
random: 
	@make --no-print-directory -f $(MAKEFILE) show PONY=$(PONY)

$(DATADIR):
	$(MAKE_DIR) $(DATADIR)
	
$(BINDIR):
	$(MAKE_DIR) $(BINDIR)

install: $(OUT_ALL)
install: $(DATADIR)
install: $(BINDIR)
	$(INSTALL_DIR) $(MAKEFILE_DIR)rendered $(DATADIR)
	$(INSTALL_FILE) $(MAKEFILE_DIR)systempony $(BINDIR)
	
uninstall:
	$(UNINSTALL_DIR) $(DATADIR)
	$(UNINSTALL_FILE) $(BINDIR)/systempony
	$(call REMOVE_DIR, $(DATADIR) $(DATAROOT) $(BINDIR))

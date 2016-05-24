PREFIX?=/usr/local
DATAROOT=$(PREFIX)/share
DATADIR=$(DATAROOT)/ascii-pony
BINDIR=$(PREFIX)/bin

MAKEFILE=$(lastword $(MAKEFILE_LIST))
MAKEFILE_DIR=$(dir $(MAKEFILE))
PONY_DIR=$(MAKEFILE_DIR)Ponies
SCRIPT_INTERPRETER=$(MAKEFILE_DIR)patsi/.env/bin/python
SCRIPT=$(MAKEFILE_DIR)patsi/patsi-render.py
OUT_DIR=$(MAKEFILE_DIR)rendered
PONIES=$(notdir $(shell find $(PONY_DIR) -maxdepth 1 -mindepth 1 -type d ))
OUT_ALL=$(foreach pony,$(PONIES),$(foreach format,$(FORMATS),$(OUT_DIR)/$(format)/$(pony).$(format)))
OUT_DIRS=$(sort $(dir $(OUT_ALL)))
find_deps=$(subst ;,\\\;,$(wildcard $(PONY_DIR)/$(1)/*))
FORMATS=txt ansi svg sh irc png

INSTALL_DIR=cp -rf
INSTALL_FILE=cp -f
UNINSTALL_DIR=rm -rf
REMOVE_FILE=rm -f
UNINSTALL_FILE=$(UNINSTALL_FILE)
REMOVE_DIR=$(foreach d, $(1), [ -d $(d) ] && rmdir $(d) || true;)
MAKE_DIR=mkdir -p

# NOTE: not .PONY :-P
.PHONY: all show show_deps clean list random install uninstall touchput

all: $(OUT_ALL)

define rule_single_output
$(OUT_DIR)/$(2)/$(1).$(2): | $(dir $(OUT_DIR)/$(2)/$(1))
$(OUT_DIR)/$(2)/$(1).$(2): $(call find_deps, $(1))
$(OUT_DIR)/$(2)/$(1).$(2): $(PONY_DIR)/$(1)
$(OUT_DIR)/$(2)/$(1).$(2): $(SCRIPT_INTERPRETER)
	$(SCRIPT_INTERPRETER) $(SCRIPT) -i $(PONY_DIR)/$(1) -o $(OUT_DIR)/$(2)/$(1).$(2)
endef

define rule_template

$(foreach format,$(FORMATS),$(eval $(call rule_single_output,$(1),$(format))))

.PHONY: $(1)
$(1) : $(foreach format,$(FORMATS),$(OUT_DIR)/$(format)/$(1).$(format))
	@cat $(OUT_DIR)/ansi/$(1).ansi

.PHONY: clean_$(1)
clean_$(1):
	$(REMOVE_FILE) $(foreach format,$(FORMATS),$(OUT_DIR)/$(format)/$(1).$(format))

endef
define dir_rule_template
$(1) : 
	$(MAKE_DIR) $(1)
endef

$(foreach pony,$(PONIES),$(eval $(call rule_template,$(pony))))
$(foreach directory,$(OUT_DIRS),$(eval $(call dir_rule_template,$(directory))))

show: $(OUT_DIR)/ansi/$(PONY).ansi
	@cat $(OUT_DIR)/ansi/$(PONY).ansi
	
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
	$(INSTALL_DIR) $(OUT_DIR) $(DATADIR)
	$(INSTALL_FILE) $(MAKEFILE_DIR)systempony $(BINDIR)
	
uninstall:
	$(UNINSTALL_DIR) $(DATADIR)
	$(UNINSTALL_FILE) $(BINDIR)/systempony
	$(call REMOVE_DIR, $(DATADIR) $(DATAROOT) $(BINDIR))

#touch output files to avoid re-generations (eg: after cloning)
touchput:
	find $(PONY_DIR) -name '*.txt' -exec touch {} \;
	find $(OUT_DIR) -exec touch {} \;
	find $(OUT_DIR) -name '*.png' -exec touch {} \;

$(SCRIPT_INTERPRETER): $(MAKEFILE_DIR)patsi/setup-env.sh
$(SCRIPT_INTERPRETER): $(MAKEFILE_DIR)patsi/requirements.pip
	$(MAKEFILE_DIR)patsi/setup-env.sh

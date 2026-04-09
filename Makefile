NVIM_BIN ?= nvim

.PHONY: test lint helptags

test:
	$(NVIM_BIN) --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/executioner/ { minimal_init = 'tests/minimal_init.lua' }"

lint:
	stylua --check lua/ tests/

helptags:
	$(NVIM_BIN) --headless -c "helptags doc/" -c "qa"

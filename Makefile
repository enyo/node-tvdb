BIN = @./node_modules/mocha/bin/mocha

test:
	@mkdir -p lib/
	@cp src/keymap.json lib/
	$(BIN) --compilers coffee:coffee-script

.PHONY: test

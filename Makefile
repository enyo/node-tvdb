BIN = @./node_modules/mocha/bin/mocha

test:
	$(BIN) --compilers coffee:coffee-script

.PHONY: test

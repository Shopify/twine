TEST_FILES=$(shell find test/*.coffee)

# For continuous rebuild of packages: `watch make .all`
.all: .app .test
	touch .all

# for now, exactly the same as .all
.pretestem: .all

.app:
	node_modules/.bin/coffee --no-header -o dist/ -c lib/assets/javascripts/twine.coffee

.test: $(TEST_FILES)
	node_modules/.bin/browserify $(TEST_FILES) -o test/test_bundle.js -t coffeeify

.uglify: .app
	node_modules/.bin/uglifyjs dist/twine.js -o dist/twine.min.js

APP_FILES=$(shell find lib/assets/**/*.coffee)
TEST_FILES=$(shell find test/*.coffee)

# For continuous rebuild of packages: `watch make .all`
.all: .app .test
	touch .all

# for now, exactly the same as .all
.pretestem: .all

.app: $(APP_FILES)
	node_modules/.bin/browserify $(APP_FILES) -o dist/twine.js -t coffeeify

.test: $(TEST_FILES)
	node_modules/.bin/browserify $(TEST_FILES) -o test/test_bundle.js -t coffeeify

.uglify: .app
	node_modules/.bin/uglifyjs dist/twine.js -o dist/twine.min.js

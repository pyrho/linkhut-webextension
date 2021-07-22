_default:
  @just --list

# Package the extension into a zip
build: _build-extension _build-elm

_build-extension: install-dependencies
    npx web-ext build -s extension -o

_build-elm: install-dependencies
    elm make src/Popup.elm --output extension/popup/elm.js
    elm make src/Options.elm --output extension/options/options.js

# Install required dependencies
install-dependencies: _install-node-deps

_install-node-deps:
    npm install

# Run linters
lint: _lint-extension _lint-elm

_lint-extension:
    npx web-ext lint -s extension

_lint-elm:
    npx elm-review --template jfmengels/elm-review-unused/example

# Sign and upload a new version of the extension to AMO
sign: build
    npx web-ext -s extension sign --api-key=$AMO_JWT_ISSUER --api-secret=$AMO_JWT_SECRET

# Continuously watch & build the code (.js and .elm) and refresh the extension as needed
debug:
    npx concurrently "just _options-watch" "just _popup-watch" "just _extension-watch"

_extension-watch:
    npx web-ext run --verbose -s extension

_options-watch:
    elm-live src/Options.elm --start-page=extension/options/options.html -- --output=extension/options/options.js

_popup-watch:
    elm-live src/Popup.elm --start-page=extension/popup/popup.html -- --output=extension/popup/elm.js

_default:
  @just --list

# Package the extension into a zip
build: _build-extension _build-popup

_build-extension: install-dependencies
    npx web-ext build -s extension -o

_build-popup: install-dependencies
    elm make src/Popup.elm --output extension/popup/elm.js

# Install required dependencies
install-dependencies: _install-node-deps

_install-node-deps:
    npm install

# Run linters
lint: _lint-extension _lint-popup

_lint-extension:
    npx web-ext lint -s extension

_lint-popup:
    npx elm-review --template jfmengels/elm-review-unused/example

# Sign and upload a new version of the extension to AMO
sign: build
    npx web-ext -s extension sign --api-key=$AMO_JWT_ISSUER --api-secret=$AMO_JWT_SECRET

# Continuously watch & build the code (.js and .elm) and refresh the extension as needed
debug:
    npx concurrently "just _popup-watch" "just _extension-watch"

_extension-watch:
    npx web-ext run --verbose -s extension

_popup-watch:
    elm-live src/Popup.elm --start-page=extension/popup/popup.html -- --output=extension/popup/elm.js

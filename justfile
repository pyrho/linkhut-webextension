default:
  @just --list

# Package the extension
build:
    @npx web-ext build -s extension

lint:
    @npx web-ext lint -s extension

# Sign the extension
sign: build
    @npx web-ext -s extension sign --api-key=$AMO_JWT_ISSUER --api-secret=$AMO_JWT_SECRET

# Package the extension and load a temporary Firefox instance with the extension
debug:
    @npx web-ext run --verbose -s extension

elm-popup:
    @elm make src/elm/Popup.elm --output extension/popup/elm-popup.js

elm-debug:
    @elm-live src/elm/Popup.elm --start-page=extension/popup/popup.html -- --output=extension/popup/elm.js

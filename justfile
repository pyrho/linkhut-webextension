default:
  @just --list

# Package the extension
build: elm-popup
    @npx web-ext build -s extension -o

lint:
    @npx web-ext lint -s extension

# Sign the extension
sign: build
    @npx web-ext -s extension -o sign --api-key=$AMO_JWT_ISSUER --api-secret=$AMO_JWT_SECRET

# Package the extension and load a temporary Firefox instance with the extension
debug: elm-popup
    @npx web-ext run --verbose -s extension

elm-popup:
    @elm make src/Popup.elm --output extension/popup/elm.js

elm-debug:
    @elm-live src/Popup.elm --start-page=extension/popup/popup.html -- --output=extension/popup/elm.js

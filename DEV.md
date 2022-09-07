Developper "documentation"
==========================

The popup
---------

The popup instance comes to existence when the user clicks the extension button in the toolbar.

### Elm / JS

The popup is developped using Elm, the code is located at `src/Popup.elm`.
This Elm application is initialized via JS in the
`extension/popup/elm-popup-loader.js` file.

### First launch

Upon first launch the extension would not have been authorized via Oauth to
interact with the user's account.
So the 

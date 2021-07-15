module Config exposing (..)

{-| Hold constant config values
Switch `isDebug` to `True` to enable testing the extension against a local instance
of linkhut.
-}


isDebug : Bool
isDebug =
    True


apiBaseUrl : String
apiBaseUrl =
    if isDebug then
        "http://10-25-47-4.sslip.io:4000/_"

    else
        "https://api.ln.ht"

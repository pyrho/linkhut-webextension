port module Options exposing (main)

-- import Json.Decode as D

import Browser
import Colors exposing (black, darkerYellow, yellow)
import Element exposing (Element, alignRight, centerX, centerY, column, el, fill, padding, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Input as Input
import Html
import Json.Encode



-- CONSTANTS


defaultWebUrl : String
defaultWebUrl =
    "https://ln.ht/"


defaultApiUrl : String
defaultApiUrl =
    "https://api.ln.ht/"


defaultClientId : String
defaultClientId =
    "90e66396114916ee104193f7b1c6171dfc3e4a9497db246db60646ba8135b780"


defaultClientSecret : String
defaultClientSecret =
    "62cf230387f4c1706dbe7edbc29a6fc5386f0f401af8c0a648038bba8c972aa8"



-- TYPES


type SendMessage
    = SaveToJs
    | ResetToJs


type alias JSMessage =
    { action : String
    , data : Maybe Json.Encode.Value
    }


type Msg
    = Save
    | Reset
    | WebUrlUpdated String
    | ApiUrlUpdated String
    | ClientIdUpdated String
    | ClientSecretUpdated String
    | Recv String


type alias Flags =
    { webUrl : Maybe String
    , apiUrl : Maybe String
    , clientId : Maybe String
    , clientSecret : Maybe String
    }


type alias Model =
    { webUrl : String
    , apiUrl : String
    , clientId : String
    , clientSecret : String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init { webUrl, apiUrl, clientId, clientSecret } =
    ( { webUrl = Maybe.withDefault defaultWebUrl webUrl
      , apiUrl = Maybe.withDefault defaultApiUrl apiUrl
      , clientId = Maybe.withDefault defaultClientId clientId
      , clientSecret = Maybe.withDefault defaultClientSecret clientSecret
      }
    , Cmd.none
    )



-- VIEW


inputField : String -> String -> (String -> Msg) -> Element Msg
inputField value label onChangeHandler =
    el
        [ width fill, padding 20 ]
    <|
        Input.text []
            { text = value
            , placeholder = Nothing
            , label = Input.labelAbove [ centerX ] <| text label
            , onChange = onChangeHandler
            }


view : Model -> Html.Html Msg
view model =
    Element.layout [] <|
        column
            [ width fill, centerY, centerX, spacing 10 ]
            [ inputField model.webUrl "Web URL" WebUrlUpdated
            , inputField model.apiUrl "API URL" ApiUrlUpdated
            , inputField model.clientId "Oauth Client ID" ClientIdUpdated
            , inputField model.clientSecret "Oauth Client Secret" ClientSecretUpdated
            , row [ centerX, spacing 50 ]
                [ Input.button
                    [ Background.color <| yellow
                    , Border.color darkerYellow
                    , Border.widthEach { bottom = 3, top = 0, right = 3, left = 0 }
                    , padding 10
                    , Border.rounded 3
                    , centerX

                    -- , E.mouseOver [ Background.color darkerYellow ]
                    ]
                    { onPress = Just Save, label = text "Save" }
                , Input.button
                    [ Background.color <| darkerYellow
                    , Border.color black
                    , Border.widthEach { bottom = 3, top = 0, right = 3, left = 0 }
                    , padding 10
                    , Border.rounded 3
                    , centerX

                    -- , E.mouseOver [ Background.color darkerYellow ]
                    ]
                    { onPress = Just Reset, label = text "Reset" }
                ]
            ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WebUrlUpdated newUrl ->
            ( { model | webUrl = newUrl }, Cmd.none )

        ApiUrlUpdated newUrl ->
            ( { model | apiUrl = newUrl }, Cmd.none )

        Save ->
            ( model, messageToJs SaveToJs model )

        Reset ->
            ( model, messageToJs ResetToJs model )

        Recv message ->
            case message of
                "resetDone" ->
                    ( { webUrl = defaultWebUrl
                      , apiUrl = defaultApiUrl
                      , clientId = defaultClientId
                      , clientSecret = defaultClientSecret
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClientIdUpdated newId ->
            ( { model | clientId = newId }, Cmd.none )

        ClientSecretUpdated newSecret ->
            ( { model | clientSecret = newSecret }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver Recv



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


messageToJs : SendMessage -> Model -> Cmd msg
messageToJs msg model =
    case msg of
        ResetToJs ->
            sendMessage { action = "reset", data = Just Json.Encode.null }

        SaveToJs ->
            let
                data =
                    Json.Encode.object
                        [ ( "webUrl", Json.Encode.string model.webUrl )
                        , ( "apiUrl", Json.Encode.string model.apiUrl )
                        , ( "clientId", Json.Encode.string model.clientId )
                        , ( "clientSecret", Json.Encode.string model.clientSecret )
                        ]
            in
            sendMessage { action = "save", data = Just <| data }


port sendMessage : JSMessage -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg

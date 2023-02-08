port module Options exposing (main)

-- import Json.Decode as D

import Browser
import Colors exposing (black, darkerYellow, yellow)
import Element exposing (Element, centerX, centerY, column, el, fill, padding, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
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
    | PersonalAccessTokenUpdated String
    | Recv String


type alias Flags =
    { webUrl : Maybe String
    , apiUrl : Maybe String
    , personalAccessToken : Maybe String
    }


type alias Model =
    { webUrl : String
    , apiUrl : String
    , personalAccessToken : Maybe String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init { webUrl, apiUrl, personalAccessToken } =
    ( { webUrl = Maybe.withDefault defaultWebUrl webUrl
      , apiUrl = Maybe.withDefault defaultApiUrl apiUrl
      , personalAccessToken =
            personalAccessToken
                |> Maybe.andThen
                    (\pat ->
                        if String.isEmpty pat then
                            Nothing

                        else
                            Just pat
                    )
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
            , inputField (Maybe.withDefault "" model.personalAccessToken) "Personal Access Token" PersonalAccessTokenUpdated
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
                      , personalAccessToken = Nothing
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        PersonalAccessTokenUpdated newToken ->
            ( { model | personalAccessToken = if String.isEmpty newToken then Nothing else Just newToken}, Cmd.none )



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
                        , ( "personalAccessToken", Json.Encode.string (Maybe.withDefault "" model.personalAccessToken) )
                        ]
            in
            sendMessage { action = "save", data = Just <| data }


port sendMessage : JSMessage -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg

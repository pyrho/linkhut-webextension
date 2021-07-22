port module Options exposing (main)

-- import Json.Decode as D

import Browser
import Colors exposing (darkerYellow, yellow)
import Element exposing (Element, alignRight, centerX, centerY, column, el, fill, padding, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Font as Font
import Element.Input as Input
import Html
import Json.Encode



-- TYPES


type SendMessage
    = SaveToJs


type alias JSMessage =
    { action : String
    , data : Maybe Json.Encode.Value
    }


type Msg
    = Save
    | WebUrlUpdated String
    | ApiUrlUpdated String
    | Recv String


type alias Flags =
    { webUrl : Maybe String
    , apiUrl : Maybe String
    }


type alias Model =
    { webUrl : String
    , apiUrl : String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init { webUrl, apiUrl } =
    ( { webUrl = Maybe.withDefault "https://ln.ht/" webUrl
      , apiUrl = Maybe.withDefault "https://api.ln.ht/" apiUrl
      }
    , Cmd.none
    )



-- VIEW


myElement : Element msg
myElement =
    el
        [ Background.color (rgb255 240 0 245)
        , Font.color (rgb255 255 255 255)
        , rounded 3
        , padding 3
        ]
        (text "stylishn")


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
            , Input.button
                [ Background.color <| yellow
                , Border.color darkerYellow
                , Border.widthEach { bottom = 3, top = 0, right = 3, left = 0 }
                , padding 10
                , Border.rounded 3
                , centerX

                -- , E.mouseOver [ Background.color darkerYellow ]
                ]
                { onPress = Just Save, label = text "Save" }
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

        _ ->
            ( model, Cmd.none )



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
        SaveToJs ->
            let
                data =
                    Json.Encode.object
                        [ ( "webUrl", Json.Encode.string model.webUrl )
                        , ( "apiUrl", Json.Encode.string model.apiUrl )
                        ]
            in
            sendMessage { action = "save", data = Just <| data }


port sendMessage : JSMessage -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg

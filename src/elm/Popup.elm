port module Popup exposing (main)

import Browser
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html
import Http
import Json.Decode as D
import Url.Builder as B



-- UTILS


createButton : String -> Msg -> E.Element Msg
createButton label msg =
    Input.button
        [ Background.color <| yellow
        , Border.color darkerYellow
        , Border.widthEach { bottom = 3, top = 0, right = 3, left = 0 }
        , E.padding 10
        , Border.rounded 3
        , E.centerX

        -- , E.mouseOver [ Background.color darkerYellow ]
        ]
        { onPress = Just msg
        , label = E.el [ E.centerX ] <| E.text label
        }


justOrEmptyString : Maybe String -> String
justOrEmptyString j =
    case j of
        Just e ->
            e

        Nothing ->
            ""



-- CONSTANTS


yellow : E.Color
yellow =
    E.rgb255 255 215 0


darkerYellow : E.Color
darkerYellow =
    E.rgb255 122 104 0


black : E.Color
black =
    E.rgb255 0 0 0



-- cyan : E.Color
-- cyan =
--     E.rgb255 0 255 215
-- darkCyan : E.Color
-- darkCyan =
--     E.rgb255 5 170 145
-- MODEL


type alias SendMessage =
    { action : String }


type Page
    = AuthorizePage
    | SaveLinkPage
    | SaveSuccess
    | SaveFailure Http.Error


type Msg
    = StartAuthorization
    | Recv String
    | UpdateUrl String
    | UpdateTitle String
    | UpdateNote String
    | UpdateTags String
    | SendIt
    | LinkAdded (Result Http.Error String)


type alias SaveLinkModel =
    { url : String
    , title : String
    , notes : Maybe String
    , tags : Maybe String
    , accessToken : String
    }


type alias AccessToken =
    String


type Model2
    = LoggedOutModel (Maybe AccessToken)
    | LoggedInModel SaveLinkModel


type alias Model =
    { currentPage : Page
    , accessToken : Maybe String
    , url : Maybe String
    , note : Maybe String
    , title : Maybe String
    , tags : Maybe String
    }


type alias Flags =
    { title : Maybe String
    , url : Maybe String
    , accessToken : Maybe String
    }



-- INIT


{-| The refreshToken passed as Flags can be Nothing

    flags(refreshToken): the browser.storage stored refreshToken or null if not present

-}
init : Flags -> ( Model, Cmd Msg )
init { title, url, accessToken } =
    ( { currentPage =
            case accessToken of
                Just _ ->
                    SaveLinkPage

                Nothing ->
                    AuthorizePage
      , accessToken = accessToken
      , url = url
      , title = title
      , note = Nothing
      , tags = Nothing
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver Recv



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAuthorization ->
            ( model, sendMessage { action = "auth" } )

        Recv _ ->
            ( model, Cmd.none )

        UpdateUrl newUrl ->
            ( { model | url = Just newUrl }, Cmd.none )

        UpdateTitle newTitle ->
            ( { model | title = Just newTitle }, Cmd.none )

        UpdateNote newNote ->
            ( { model | note = Just newNote }, Cmd.none )

        UpdateTags newTags ->
            ( { model | tags = Just newTags }, Cmd.none )

        LinkAdded x ->
            case x of
                Ok _ ->
                    ( { model | currentPage = SaveSuccess }, sendMessage { action = "success" } )

                Err e ->
                    ( { model | currentPage = SaveFailure e }, Cmd.none )

        SendIt ->
            ( model, postLink model )


postLink : Model -> Cmd Msg
postLink model =
    let
        base =
            "http://10-25-47-4.sslip.io:4000/_"

        url : String
        url =
            B.crossOrigin base
                [ "v1", "posts", "add" ]
                [ B.string "description" (justOrEmptyString model.title)
                , B.string "extended" (justOrEmptyString model.note)
                , B.string "url" (justOrEmptyString model.url)
                , B.string "tags" (justOrEmptyString model.tags)
                ]
    in
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-Type" "application/json"
            , Http.header "Authorization" <| "Bearer " ++ justOrEmptyString model.accessToken
            ]
        , url = url
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson LinkAdded (D.field "result_code" D.string)
        }



-- VIEW


header : E.Element Msg
header =
    let
        style =
            [ E.width E.fill
            , E.paddingXY 20 20
            , E.spacing 20
            , Border.width 1
            , Border.color black
            , Background.color yellow
            ]
    in
    E.row style
        [ E.el [ E.alignLeft ] <|
            E.image
                [ E.width <| E.px 20
                ]
                { src = "/icons/icon.svg"
                , description = "logo"
                }
        , E.el
            [ Region.heading 1
            , Font.extraBold
            , Font.size 26
            ]
          <|
            E.text "Save to LinkHut"
        ]


layout : E.Element msg -> Html.Html msg
layout =
    E.layoutWith
        { options =
            [ E.focusStyle
                { borderColor = Nothing
                , backgroundColor = Nothing
                , shadow = Nothing
                }
            ]
        }
        []


{-| The view element used to save links
-}
saveLinkView : Model -> Html.Html Msg
saveLinkView model =
    let
        labelStyle =
            [ Font.extraBold
            , Font.size 20
            , Region.heading 1
            ]

        textInputStyle =
            [ Font.size 12
            ]
    in
    layout <|
        E.column [ E.width E.fill, E.padding 10, E.spacing 10 ]
            [ header
            , Input.text textInputStyle
                { text = justOrEmptyString model.title
                , label =
                    Input.labelAbove labelStyle <| E.text "Title"
                , placeholder = Nothing
                , onChange = UpdateTitle
                }
            , Input.text
                textInputStyle
                { text = justOrEmptyString model.url
                , label =
                    Input.labelAbove labelStyle <| E.text "Url"
                , placeholder = Nothing
                , onChange = UpdateUrl
                }
            , Input.multiline
                ([ E.width <| E.maximum 450 E.fill
                 , E.height <| E.px 150
                 ]
                    ++ textInputStyle
                )
                { onChange = UpdateNote
                , text = justOrEmptyString model.note
                , placeholder = Nothing
                , label = Input.labelAbove labelStyle <| E.text "Notes"
                , spellcheck = True
                }
            , Input.text
                textInputStyle
                { text = justOrEmptyString model.tags
                , label =
                    Input.labelAbove labelStyle <| E.text "Tags"
                , placeholder = Nothing
                , onChange = UpdateTags
                }
            , createButton "Save" SendIt
            ]


{-| The view element when the user is not logged in yet
-}
authorizeView : Html.Html Msg
authorizeView =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el [ E.centerX, E.centerY, E.paddingXY 0 30 ] <|
                createButton "Authorize" StartAuthorization
            ]


successView : Html.Html Msg
successView =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el [ E.centerX, E.centerY, E.paddingXY 0 30 ] <|
                E.image
                    [ E.width <| E.px 80
                    ]
                    { src = "/icons/success-green-check-mark.svg"
                    , description = "logo"
                    }
            ]


failureView : Http.Error -> Html.Html Msg
failureView _ =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el
                [ Region.heading 1
                , E.centerX
                , E.centerY
                , E.paddingXY 0 30
                , Font.extraBold
                , Font.size 20
                , Font.color <| E.rgb255 255 0 0
                ]
              <|
                E.text "An error occured t__t"
            ]


view : Model -> Html.Html Msg
view ({ currentPage } as model) =
    case currentPage of
        SaveLinkPage ->
            saveLinkView model

        AuthorizePage ->
            authorizeView

        SaveSuccess ->
            successView

        SaveFailure e ->
            failureView e



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- PORTS


port sendMessage : SendMessage -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg

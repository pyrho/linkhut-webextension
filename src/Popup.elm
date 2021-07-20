port module Popup exposing (main)

{-| The module represents the contents of the extension popup.
-}

import Browser
import Config
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html
import Http
import Json.Decode as D
import Json.Encode
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



-- MODEL


type Model
    = Unauthorized
    | SavePage AccessToken Link
    | ShowError String
    | SaveSuccess


type SendMessage
    = StartAuthorizationMessage
    | LinkSavedMessage
    | GetTabInfoMessage


type alias JSMessage =
    { action : String
    , data : Maybe Json.Encode.Value
    }


type alias JSMessageGetTabInfo =
    { url : String
    , title : String
    , accessToken : String
    }


type Msg
    = StartAuthorization
    | Recv JSMessage
    | UpdateUrl String
    | UpdateTitle String
    | UpdateNote String
    | UpdateTags String
    | SendIt
    | LinkAdded (Result Http.Error String)


{-| Represents a link to be saved via the API

Maybe's represent optional fields in the /posts/add request.

-}
type alias Link =
    { url : String
    , description : String
    , extended : Maybe String
    , tags : Maybe String
    , dt : Maybe String
    , replace : Bool
    , shared : Bool
    }


newLink : { title : String, url : String } -> Link
newLink { title, url } =
    Link
        url
        title
        Nothing
        Nothing
        Nothing
        -- We default to "Replace:yes" because as of 2021-07-20 the API will
        -- return "something went wrong" if the link already exists
        True
        True


type alias AccessToken =
    String


{-| Flags sent from JS land.

    title: is the title of the web page to save
    url: is the url of the web page to save
    accessToken: is retrieved from local storage

-}
type alias Flags =
    { title : Maybe String
    , url : Maybe String
    , accessToken : Maybe String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init { title, url, accessToken } =
    case ( title, url, accessToken ) of
        ( Just title_, Just url_, Just accessToken_ ) ->
            ( SavePage accessToken_ (newLink { title = title_, url = url_ }), Cmd.none )

        ( _, _, Nothing ) ->
            ( Unauthorized, Cmd.none )

        _ ->
            ( ShowError "Unexpected state at init", Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver Recv



-- UPDATE


tabInfoDecoder : D.Decoder JSMessageGetTabInfo
tabInfoDecoder =
    D.map3 JSMessageGetTabInfo
        (D.field "url" D.string)
        (D.field "title" D.string)
        (D.field "accessToken" D.string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( StartAuthorization, _ ) ->
            ( model, messageToJs StartAuthorizationMessage )

        ( Recv { action, data }, _ ) ->
            case ( action, data ) of
                -- After the user did "Authorize" but things turned to shit
                ( "error", _ ) ->
                    ( ShowError "Error from JS land.", Cmd.none )

                -- After the user did "Authorize" and everything went well
                ( "authSuccess", _ ) ->
                    ( model, messageToJs GetTabInfoMessage )

                -- After successful authorization, we explicitely ask the JS for the
                -- updated data.
                --
                -- @NOTE
                --  this data could be passed on directly via the `authSuccess`
                --  message but I wanted to try out a more complex flow (:
                --    - dr, 2021-07-20
                ( "tabInfo", Just data_ ) ->
                    case D.decodeValue tabInfoDecoder data_ of
                        Ok v ->
                            ( SavePage v.accessToken <| newLink { title = v.title, url = v.url }
                            , Cmd.none
                            )

                        Err e ->
                            ( ShowError <| "Failed to decode tabInfo: " ++ D.errorToString e
                            , Cmd.none
                            )

                ( "tabInfo", Nothing ) ->
                    ( ShowError <| "TabInfo had null data key", Cmd.none )

                _ ->
                    ( ShowError <| "Unexpected message from JS" ++ action, Cmd.none )

        {--
            case action of
                "authSuccess" ->
                    ( model, messageToJs GetTabInfoMessage )

                "tabInfo" ->
                    case data of
                        Just data_ ->
                            case D.decodeValue tabInfoDecoder data_ of
                                Ok v ->
                                    ( SavePage v.accessToken <| newLink { title = v.title, url = v.url }
                                    , Cmd.none
                                    )

                                Err e ->
                                    ( ShowError <| "Failed to decode tabInfo: " ++ D.errorToString e
                                    , Cmd.none
                                    )

                        Nothing ->
                            ( ShowError <| "Unexpected message from JS " ++ action
                            , Cmd.none
                            )

                "error" ->
                    ( model, Cmd.none )

                _ ->
                    ( ShowError <| "Unexpected message from JS" ++ action, Cmd.none )
-}
        ( UpdateUrl newUrl, SavePage token link ) ->
            ( SavePage token { link | url = newUrl }, Cmd.none )

        ( UpdateTitle newTitle, SavePage token link ) ->
            ( SavePage token { link | description = newTitle }, Cmd.none )

        ( UpdateNote newNote, SavePage token link ) ->
            ( SavePage token { link | extended = Just newNote }, Cmd.none )

        ( UpdateTags newTags, SavePage token link ) ->
            ( SavePage token { link | tags = Just newTags }, Cmd.none )

        ( SendIt, SavePage token link ) ->
            ( model, postLink token link )

        ( LinkAdded res, _ ) ->
            case res of
                Ok apiResponseCode ->
                    case apiResponseCode of
                        "done" ->
                            ( SaveSuccess, messageToJs LinkSavedMessage )

                        _ ->
                            ( ShowError <| "Failed adding link, api said: " ++ apiResponseCode
                            , Cmd.none
                            )

                Err httpError ->
                    let
                        errString =
                            case httpError of
                                Http.BadUrl x ->
                                    "BadUrl: " ++ x

                                Http.Timeout ->
                                    "Timeout"

                                Http.NetworkError ->
                                    "NetErr"

                                Http.BadStatus x ->
                                    "BadStatus: " ++ String.fromInt x

                                Http.BadBody x ->
                                    "BadBody: " ++ x
                    in
                    ( ShowError <| "There was an error with the request" ++ errString, Cmd.none )

        _ ->
            ( ShowError "Unexpected state at update", Cmd.none )


postLink : AccessToken -> Link -> Cmd Msg
postLink token { url, description, extended, tags, dt, replace, shared } =
    let
        boolToApiString : Bool -> String
        boolToApiString b =
            if b then
                "yes"

            else
                "no"

        mandatoryParameters : List ( String, String )
        mandatoryParameters =
            [ ( "description", description )
            , ( "url", url )
            , ( "replace", boolToApiString replace )
            , ( "shared", boolToApiString shared )
            ]

        optionalParameters : List ( String, String )
        optionalParameters =
            [ ( "extended", extended )
            , ( "tags", tags )
            , ( "dt", dt )
            ]
                |> List.filterMap (\( name, value ) -> Maybe.map (Tuple.pair name) value)

        queryParameters : List B.QueryParameter
        queryParameters =
            mandatoryParameters
                ++ optionalParameters
                |> List.map (\( n, v ) -> B.string n v)

        builtUrl : String
        builtUrl =
            B.crossOrigin Config.apiBaseUrl
                [ "v1", "posts", "add" ]
                queryParameters

        headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-Type" "application/json"
            , Http.header "Authorization" <| "Bearer " ++ token
            ]
    in
    Debug.log builtUrl
    Http.request
        { method = "GET"
        , headers = headers
        , url = builtUrl
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
saveLinkView : Link -> Html.Html Msg
saveLinkView link =
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
        E.column [ E.width E.fill, E.padding 10, E.spacing 20 ]
            [ header
            , Input.text textInputStyle
                { text = link.description
                , label =
                    Input.labelAbove labelStyle <| E.text "Title"
                , placeholder = Nothing
                , onChange = UpdateTitle
                }
            , Input.text
                textInputStyle
                { text = link.url
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
                , text = Maybe.withDefault "" link.extended
                , placeholder = Nothing
                , label = Input.labelAbove labelStyle <| E.text "Notes"
                , spellcheck = True
                }
            , Input.text
                textInputStyle
                { text = Maybe.withDefault "" link.tags
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


{-| The view once the link has been saved
-}
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


{-| The view if there was an error
-}
showMessageView : String -> List (E.Attribute Msg) -> Html.Html Msg
showMessageView msg extraAttributes =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el
                ([ Region.heading 1
                 , E.centerX
                 , E.centerY
                 , E.paddingXY 0 30
                 , Font.extraBold
                 , Font.size 20
                 ]
                    ++ extraAttributes
                )
              <|
                E.text <|
                    msg
            ]


view : Model -> Html.Html Msg
view model =
    case model of
        Unauthorized ->
            authorizeView

        SavePage _ link ->
            saveLinkView link

        SaveSuccess ->
            successView

        ShowError m ->
            showMessageView m [ Font.color <| E.rgb255 255 0 0 ]



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


{-| Helper function to send messages to JS land.
-}
messageToJs : SendMessage -> Cmd msg
messageToJs msg =
    case msg of
        GetTabInfoMessage ->
            sendMessage { action = "getTabInfo", data = Nothing }

        StartAuthorizationMessage ->
            sendMessage { action = "auth", data = Nothing }

        LinkSavedMessage ->
            sendMessage { action = "success", data = Nothing }


port sendMessage : JSMessage -> Cmd msg


port messageReceiver : (JSMessage -> msg) -> Sub msg

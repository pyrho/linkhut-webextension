port module Popup exposing (main)

{-| The standalone Elm app represents the contents of the extension popup.
-}

import Browser
import Colors exposing (black, darkerYellow, yellow)
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


existingLinkToLink : ExistingLink -> Link -> Link
existingLinkToLink existingLink link =
    { link
        | description = existingLink.description
        , extended = existingLink.extended
        , replace = True
        , tags =
            if String.isEmpty existingLink.tags then
                Nothing

            else
                Just existingLink.tags
    }


httpErrorHandler : Http.Error -> String
httpErrorHandler httpError =
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


linkDecoder : D.Decoder (List ExistingLink)
linkDecoder =
    D.field "posts"
        (D.list
            (D.map6 ExistingLink
                (D.field "description" D.string)
                (D.maybe (D.field "extended" D.string))
                (D.field "hash" D.string)
                (D.field "href" D.string)
                (D.field "tags" D.string)
                (D.field "time" D.string)
            )
        )


{-| Fetches a given link from the API.

    fetchLinkDataFromApi "https://ln.ht" "bearertoken" "https://api.ln.ht"

-}
fetchLinkDataFromApi : String -> String -> String -> Cmd Msg
fetchLinkDataFromApi currentUrl token apiUrl =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Content-Type" "application/json"
            , Http.header "Authorization" <| "Bearer " ++ token
            ]
        , url =
            B.crossOrigin apiUrl
                [ "_", "v1", "posts", "get" ]
                [ B.string "url" currentUrl ]
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson GotLinkQueryResponse linkDecoder
        }


createButton : String -> Msg -> E.Element Msg
createButton label msg =
    Input.button
        [ Background.color <| yellow
        , Border.color darkerYellow
        , Border.widthEach { bottom = 3, top = 0, right = 3, left = 0 }
        , E.padding 10
        , Border.rounded 3
        , E.centerX
        , E.mouseOver [ Background.color darkerYellow ]
        ]
        { onPress = Just msg
        , label = E.el [ E.centerX ] <| E.text label
        }



-- CONSTANTS
-- yellow : E.Color
-- yellow =
--     E.rgb255 255 215 0
-- darkerYellow : E.Color
-- darkerYellow =
--     E.rgb255 122 104 0
-- black : E.Color
-- black =
--     E.rgb255 0 0 0
-- MODEL


type alias ApiUrl =
    String


{-|

    <post description="sourcehut - the hacker's forge"
          extended="sourcehut is a network of useful open source tools for software project maintainers and collaborators, including git repos, bug tracking, continuous integration, and mailing lists."
          hash="f76bae21f8ea04facdb544655745c924"
          href="https://sourcehut.org/"
          others="0"
          tag="git oss software-forge"
          time="2020-12-23T19:51:48Z"/>

-}
type alias ExistingLink =
    { description : String
    , extended : Maybe String
    , hash : String
    , href : String
    , tags : String
    , time : String
    }


type Model
    -- `Unauthorized` when the PersonalAccessToken is None
    = Unauthorized
    | Authorized AccessToken Link ApiUrl
    | SavePage AccessToken Link ApiUrl (Maybe String)
    | ShowError String
    | SaveSuccess


type SendMessage
    = LinkSavedMessage


type alias JSMessage =
    { action : String
    , data : Maybe Json.Encode.Value
    }


type alias JSMessageGetTabInfo =
    { url : String
    , title : String
    }


type Msg
    = Recv JSMessage
    | UpdateUrl String
    | UpdateTitle String
    | UpdateNote String
    | UpdateTags String
    | SendIt
    | LinkAdded (Result Http.Error String)
      -- Tho the list always has one element
    | GotLinkQueryResponse (Result Http.Error (List ExistingLink))


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
        -- But the API will also reply with 404 if replace:yes and the link
        -- does not exist yet.
        -- 2022-09-06 Still the case.
        False
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
    , apiUrl : Maybe String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init { title, url, accessToken, apiUrl } =
    let
        apiUrl_ =
            Maybe.withDefault "http://api.ln.ht" apiUrl
    in
    case ( title, url, accessToken ) of
        ( Just title_, Just url_, Just accessToken_ ) ->
            let
                linkToSave =
                    newLink { title = title_, url = url_ }
            in
            ( Authorized accessToken_ linkToSave apiUrl_, fetchLinkDataFromApi linkToSave.url accessToken_ apiUrl_ )

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
    D.map2 JSMessageGetTabInfo
        (D.field "url" D.string)
        (D.field "title" D.string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of

        -- After the user did "Authorize" and everything went well
        ( Recv { action, data }, Unauthorized ) ->
            case ( action, data ) of
                ( "error", _ ) ->
                    ( ShowError "Error from JS land.", Cmd.none )

                _ ->
                    ( ShowError <| "Unexpected message from JS" ++ action, Cmd.none )

        ( Recv { action, data }, _ ) ->
            case ( action, data ) of
                -- After the user did "Authorize" but things turned to shit
                ( "error", _ ) ->
                    ( ShowError "Error from JS land.", Cmd.none )

                _ ->
                    ( ShowError <| "Unexpected message from JS" ++ action, Cmd.none )

        ( UpdateUrl newUrl, SavePage token link apiUrl savedDate ) ->
            ( SavePage token { link | url = newUrl } apiUrl savedDate, Cmd.none )

        ( UpdateTitle newTitle, SavePage token link apiUrl savedDate ) ->
            ( SavePage token { link | description = newTitle } apiUrl savedDate, Cmd.none )

        ( UpdateNote newNote, SavePage token link apiUrl savedDate ) ->
            ( SavePage token { link | extended = Just newNote } apiUrl savedDate, Cmd.none )

        ( UpdateTags newTags, SavePage token link apiUrl savedDate ) ->
            ( SavePage token { link | tags = Just newTags } apiUrl savedDate, Cmd.none )

        ( SendIt, SavePage token link apiUrl _ ) ->
            ( model, postLink apiUrl token link )

        ( GotLinkQueryResponse res, Authorized token link apiUrl ) ->
            case res of
                Ok existingLinks ->
                    case List.head existingLinks of
                        Just existingLink ->
                            ( SavePage token (existingLinkToLink existingLink link) apiUrl (Just existingLink.time), Cmd.none )

                        -- ( ShowError <| "SUCCESS, api responded: " ++ link.description, Cmd.none )
                        Nothing ->
                            -- 2022-09-07: This should never happen because if the link does not exist the API returns 404
                            -- If this starts occuring, then the API changed.
                            ( ShowError <| "Error: Link not found, this should never happen.", Cmd.none )

                Err httpError ->
                    case httpError of
                        -- This means the link was not found by the API, so it's a brand new link
                        Http.BadStatus 404 ->
                            ( SavePage token link apiUrl Nothing, Cmd.none )

                        _ ->
                            ( ShowError <| "Error getting link: " ++ httpErrorHandler httpError, Cmd.none )

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
                    ( ShowError <| "There was an error with the request" ++ httpErrorHandler httpError, Cmd.none )

        _ ->
            let
                _ =
                    Debug.log "wtf" model

                _ =
                    Debug.log "wtf2" msg
            in
            ( ShowError "Unexpected state at update", Cmd.none )


postLink : String -> AccessToken -> Link -> Cmd Msg
postLink apiUrl token { url, description, extended, tags, dt, replace, shared } =
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
            B.crossOrigin apiUrl
                [ "_", "v1", "posts", "add" ]
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
saveLinkView : Link -> Maybe String -> Html.Html Msg
saveLinkView link savedDateMaybe =
    let
        labelStyle =
            [ Font.extraBold
            , Font.size 20
            , Region.heading 1
            ]

        textInputStyle =
            [ Font.size 12
            ]

        titleElement =
            Input.text
                textInputStyle
                { text = link.description
                , label =
                    Input.labelAbove labelStyle <| E.text "Title"
                , placeholder = Nothing
                , onChange = UpdateTitle
                }

        -- If a link has been previously submitted to ln.ht it cannot be edited (only deleted).
        -- Hence in this case, the UI forbids editing the link
        urlElement =
            case savedDateMaybe of
                Just _ ->
                    E.textColumn [ E.spacing 10, E.width E.shrink ]
                        [ E.paragraph [] [ E.el labelStyle (E.text "Url") ]
                        , E.paragraph [] [ E.el textInputStyle (E.text link.url) ]
                        ]

                Nothing ->
                    Input.text
                        textInputStyle
                        { text = link.url
                        , label =
                            Input.labelAbove labelStyle <| E.text "Url"
                        , placeholder = Nothing
                        , onChange = UpdateUrl
                        }

        notesElement =
            Input.multiline
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

        tagsElement =
            Input.text
                textInputStyle
                { text = Maybe.withDefault "" link.tags
                , label =
                    Input.labelAbove labelStyle <| E.text "Tags"
                , placeholder = Nothing
                , onChange = UpdateTags
                }

        -- If the link was previously saved, show the date; otherwise show nothing.
        previouslySavedElement =
            let
                savedDateIntoHtmlText =
                    Maybe.map
                        (\savedDate -> E.el [ Font.italic, Font.size 10 ] <| E.text ("Previously saved: " ++ savedDate))
                        savedDateMaybe
            in
            Maybe.withDefault E.none savedDateIntoHtmlText

        submitBtn =
            let
                savedDateMaybeIntoText =
                    Maybe.withDefault "Save" (Maybe.map (always "Update") savedDateMaybe)
            in
            createButton savedDateMaybeIntoText SendIt
    in
    layout <|
        E.column
            [ E.width E.fill
            , E.padding 10
            , E.spacing 20
            ]
            [ header
            , titleElement
            , urlElement
            , notesElement
            , tagsElement
            , previouslySavedElement
            , submitBtn
            ]


{-| The view element when the user is not logged in yet
-}
unauthorizedView : Html.Html Msg
unauthorizedView =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el [ E.centerX, E.centerY, E.paddingXY 0 30 ] <|
                E.text "Please get an access token"
            ]


loadingView : Html.Html Msg
loadingView =
    layout <|
        E.column [ E.width E.fill, E.padding 10 ]
            [ header
            , E.el [ E.centerX, E.centerY, E.paddingXY 0 30 ] <|
                E.image
                    [ E.width <| E.px 80
                    ]
                    { src = "/icons/loading.svg"
                    , description = "loading"
                    }
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
                    , description = "success"
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
            unauthorizedView

        -- This state is used while we wait for an answer from the API
        -- to check if a link has been previously saved
        Authorized _ _ _ ->
            loadingView

        SavePage _ link _ savedDateMaybe ->
            saveLinkView link savedDateMaybe

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
        LinkSavedMessage ->
            sendMessage { action = "success", data = Nothing }


port sendMessage : JSMessage -> Cmd msg


port messageReceiver : (JSMessage -> msg) -> Sub msg

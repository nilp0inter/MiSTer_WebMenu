module Main exposing (main)

import Html exposing (..)
import Http
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Url.Builder exposing (relative, string)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Bootstrap.Navbar as Navbar
import Bootstrap.Alert as Alert
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Utilities.Spacing as Spacing
import Bootstrap.Text as Text
import Bootstrap.Spinner as Spinner
import Json.Decode as D


type PanelType =
      Info
    | Error

-- apiRoot = "http://localhost:8080"
type alias Panel =
    { title : String
    , text : String
    , style : PanelType
    , visibility : Alert.Visibility
    }

apiRoot = ""

type alias Core =
    { filename : String
    , codename : String
    }

decoder : D.Decoder Core
decoder =
  D.map2 Core
    (D.field "filename" D.string)
    (D.field "codename" D.string)

type alias Flags =
    {}

type alias Model =
    { navKey : Navigation.Key
    , page : Page

    , navState : Navbar.State

    , modalVisibility : Modal.Visibility
    , modalTitle : String
    , modalBody : String
    , modalAction : Msg

    , messages : (List Panel)
    , cores : Maybe (List Core)
    , waiting : Int
    , scanning : Bool
    }

type Page
    = Home
    | CoresPage
    | NotImplementedPage String
    | NotFound


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = UrlChange
        }

init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate url { navKey = key
                          , navState = navState
                          , page = Home
                          , modalVisibility = Modal.hidden
                          , modalTitle = ""
                          , modalBody = ""
                          , modalAction = CloseModal
                          , cores = Nothing
                          , waiting = 1
                          , scanning = False
                          , messages = [] }
    
    in
        ( model, Cmd.batch [ urlCmd, navCmd, loadCores ] )



type Msg
    = UrlChange Url
    | ClickedLink UrlRequest
    | NavMsg Navbar.State
    | CloseModal
    | ShowModal String String Msg
    | LoadGame String String
    | GameLoaded (Result Http.Error ())
    | SyncFinished (Result Http.Error ())
    | LoadCores
    | ScanCores
    | GotCores (Result Http.Error (Maybe (List Core)))
    | ClosePanel Int Alert.Visibility


subscriptions : Model -> Sub Msg
subscriptions model =
    Navbar.subscriptions model.navState NavMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink req ->
             case req of
                 Browser.Internal url ->
                     ( model, Navigation.pushUrl model.navKey <| Url.toString url )

                 Browser.External href ->
                     ( model, Navigation.load href )


        UrlChange url ->
            urlUpdate url model

        NavMsg state ->
            ( { model | navState = state }
            , Cmd.none
            )

        CloseModal ->
            ( { model | modalVisibility = Modal.hidden }
            , Cmd.none
            )

        ShowModal title body action ->
            ( { model | modalVisibility = Modal.shown
                      , modalTitle = title
                      , modalBody = body
                      , modalAction = action }
            , Cmd.none
            )

        LoadGame core game ->
            ( { model | modalVisibility = Modal.hidden }, loadGame core game )

        GameLoaded _ ->
            ( model, Cmd.none )

        LoadCores ->
            ( { model | waiting = model.waiting + 1 }, loadCores )

        GotCores c ->
            case c of
                Ok cs -> ( { model | waiting = model.waiting - 1, cores = cs }, Cmd.none )
                Err (Http.BadStatus 404) -> ( { model | waiting = model.waiting-1, cores = Nothing }, Cmd.none )
                Err e -> ( { model | waiting = model.waiting - 1
                                   , modalVisibility = Modal.shown
                                   , modalTitle = "Error!"
                                   , modalBody = errorToString e
                                   , modalAction = CloseModal}, Cmd.none )

        ScanCores ->
            ( { model | scanning = True
                      , waiting = model.waiting + 1 }, if model.scanning then Cmd.none else syncCores )

        SyncFinished c ->
            case c of
                Ok cs -> ( { model | scanning = False }, loadCores )
                Err e -> ( { model | scanning = False
                                   , waiting = model.waiting - 1 
                                   , messages = (newPanel Error "Error scanning cores" (errorToString e)) :: model.messages }, Cmd.none )

        ClosePanel id vis ->
            ( { model | messages = (List.indexedMap (changePanelVisibility vis id) model.messages) }, Cmd.none )



newPanel : PanelType -> String -> String -> Panel
newPanel ptype title text =
    { title = title
    , text = text
    , style = ptype 
    , visibility = Alert.shown }

changePanelVisibility : Alert.Visibility -> Int -> Int -> Panel -> Panel
changePanelVisibility vis id current panel = if current == id then { panel | visibility = vis } else panel

errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"
        Http.Timeout ->
            "Unable to reach the server, try again"
        Http.NetworkError ->
            "Unable to reach the server, check your network connection"
        Http.BadStatus 500 ->
            "The server had a problem, try again later"
        Http.BadStatus 400 ->
            "Verify your information and try again"
        Http.BadStatus _ ->
            "Unknown error"
        Http.BadBody errorMessage ->
            errorMessage

syncCores : Cmd Msg
syncCores =
    Http.get
      { url = relative ["api", "cores", "scan"] [ ]
      , expect = Http.expectWhatever SyncFinished
      }

loadCores : Cmd Msg
loadCores =
    Http.get
      { url = relative ["cached", "cores.json"] [ ]
      , expect = Http.expectJson GotCores (D.nullable (D.list decoder))
      }


loadGame : String -> String -> Cmd Msg
loadGame core game =
    Http.get
      { url = relative ["api", "run"] [ string "core" core, string "game" game ]
      , expect = Http.expectWhatever GameLoaded
      }

urlUpdate : Url -> Model -> ( Model, Cmd Msg )
urlUpdate url model =
    case decode url of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decode : Url -> Maybe Page
decode url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
    |> UrlParser.parse routeParser


routeParser : Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Home top
        , UrlParser.map (NotImplementedPage "Games") (UrlParser.s "games")
        , UrlParser.map CoresPage (UrlParser.s "cores")
        , UrlParser.map (NotImplementedPage "Community") (UrlParser.s "community")
        , UrlParser.map (NotImplementedPage "Settings") (UrlParser.s "settings")
        , UrlParser.map (NotImplementedPage "About") (UrlParser.s "about")
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "MiSTer WebMenu"
    , body =
        [ div []
            [ menu model
            , mainContent model
            , modal model
            ]
        ]
    }

messages : Model -> Html Msg
messages model = 
    div [ class "mb-4" ] [
        Grid.row []
            [ Grid.col [] (List.indexedMap showPanel model.messages) ] ]

showPanel : Int -> Panel -> Html Msg
showPanel id panel = 
    Alert.config
        |> Alert.dismissableWithAnimation (ClosePanel id)
        |> (case panel.style of
                Info -> Alert.info
                Error -> Alert.warning
           )
        |> Alert.children
            [ Alert.h4 [] [ text panel.title ]
            , p [] [ text panel.text ]
            ]
        |> Alert.view panel.visibility

menu : Model -> Html Msg
menu model =
    div [ class "mb-4" ] [ 
      Navbar.config NavMsg
          |> Navbar.withAnimation
          |> Navbar.container
          |> Navbar.brand [ href "#" ] [ text "MiSTer" ]
          |> Navbar.items
              [ Navbar.itemLink [ href "#cores" ] [ text "Cores" ]
              , Navbar.itemLink [ href "#games" ] [ text "Games" ]
              , Navbar.itemLink [ href "#community" ] [ text "Community" ]
              , Navbar.itemLink [ href "#settings" ] [ text "Settings" ]
              , Navbar.itemLink [ href "#about" ] [ text "About" ]
              ]
          |> Navbar.customItems
              [ Navbar.customItem (if model.waiting > 0 then ( Spinner.spinner [ Spinner.grow ] [ ] ) else ( text "" ) )
              ]
          |> Navbar.view model.navState
    ]


mainContent : Model -> Html Msg
mainContent model =
    Grid.container [] ([messages model] ++
        case model.page of
            Home ->
                pageHome model

            CoresPage ->
                pageCoresPage model

            NotImplementedPage title ->
                pageNotImplemented title

            NotFound ->
                pageNotFound
    )

pageHome : Model -> List (Html Msg)
pageHome model =
    [ Grid.row []
        [ Grid.col []
            [ p [] [ text "Welcome..." ] ]
        ]
    ]

pageNotImplemented : String -> List (Html Msg)
pageNotImplemented title = 
    [ h1 [] [ text title ]
    , Card.config [ Card.outlineInfo ]
        |> Card.block []
            [ Block.titleH3 [] [ text "Not implemented yet" ]
            , Block.text [] [ p [] [text "This feature will be available on future versions."] ]
            ]
        |> Card.view ]


pageCoresPage : Model -> List (Html Msg)
pageCoresPage model =
    case model.cores of
        Nothing ->
            case model.scanning of
                True -> waitForSync
                False -> coreSyncButton
        Just cs -> coreSelector cs


coreSelector : List Core -> List (Html Msg)
coreSelector cs = List.map toGameLauncher cs

waitForSync : List (Html Msg)
waitForSync = [
    Card.config [ Card.primary
                , Card.textColor Text.white ]
        |> Card.block []
            [ Block.titleH4 [] [ text "Please wait..." ]
            , Block.text [] [ p [] [text "WebMenu is looking for cores in your MiSTer device."]
                            , p [] [text "This may take a couple of minutes depending on the number of files in your SD card."] ]
            , Block.custom <|
                    Spinner.spinner [ ] [ ]
            ]
        |> Card.view
    ]

coreSyncButton : List (Html Msg)
coreSyncButton = [
    Card.config []
        |> Card.block []
            [ Block.titleH4 [] [ text "No cores yet" ]
            , Block.text [] [ p [] [text "Click on 'Scan now' to start scanning for available cores in your MiSTer."],
                              p [] [text "This may take a couple of minutes depending on the number of files in your SD card."] ]
            , Block.custom <|
                Button.button [ Button.primary
                              , Button.onClick ScanCores
                 ] [ text "Scan now" ]
            ]
        |> Card.view
    ]


toGameLauncher : Core -> Html Msg
toGameLauncher c = gameLauncher c.codename "" c.filename ""

gameLauncher : String -> String -> String -> String -> Html Msg
gameLauncher title body core game =
    Card.config [ Card.outlineSecondary, Card.attrs [ Spacing.mb3 ] ]
        |> Card.header [] [ text title ]
        |> Card.block [  ] [ Block.quote [] [ p [] [ text body ] ]
                           , Block.custom <|
                              Button.button [ Button.primary
                                            , Button.onClick (ShowModal "Are you sure?" ("You are about to launch " ++ title ++ ". Any running game will be stopped immediately!") (LoadGame core game)) ] [ text "Play!" ]
                           ]
        |> Card.view
    

pageNotFound : List (Html Msg)
pageNotFound =
    [ h1 [] [ text "Not found" ]
    , text "Sorry couldn't find that page"
    ]


modal : Model -> Html Msg
modal model =
    Modal.config CloseModal
        |> Modal.small
        |> Modal.h4 [] [ text model.modalTitle ]
        |> Modal.body []
            [ Grid.containerFluid []
                [ Grid.row []
                    [ Grid.col
                        [  ]
                        [ text model.modalBody ]
                    ]
                , Grid.row []
                    [ Grid.col
                        [  ]
                        [ Button.button [ Button.warning
                                        , Button.onClick model.modalAction ] [ text "Proceed" ] ]
                    ]
                ]
            ]
        |> Modal.view model.modalVisibility

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


-- apiRoot = "http://localhost:8080"
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
    , cores : List Core
    , waiting : Bool
    , scanning : Bool
    }

type Page
    = Home
    | GettingStarted
    | CoresPage
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
            urlUpdate url { navKey = key, navState = navState, page = Home, modalVisibility= Modal.hidden, modalTitle="", modalBody="", modalAction = CloseModal, cores=[], waiting=False, scanning=False }
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
    | GotCores (Result Http.Error (List Core))


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
            ( { model | waiting = True }, loadCores )

        GotCores c ->
            case c of
                Ok cs -> ( { model | waiting = False, cores = cs }, Cmd.none )
                Err e -> ( { model | waiting = False
                                   , modalVisibility = Modal.shown
                                   , modalTitle = "Error!"
                                   , modalBody = errorToString e
                                   , modalAction = CloseModal}, Cmd.none )

        ScanCores ->
            ( { model | waiting = model.waiting || not model.scanning }, if model.scanning then Cmd.none else syncCores )

        SyncFinished c ->
            case c of
                Ok cs -> ( { model | waiting = False }, loadCores )
                Err e -> ( { model | waiting = False
                                   , modalVisibility = Modal.shown
                                   , modalTitle = "Error!"
                                   , modalBody = errorToString e
                                   , modalAction = CloseModal}, Cmd.none )

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
      , expect = Http.expectJson GotCores (D.list decoder)
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
        , UrlParser.map GettingStarted (UrlParser.s "games")
        , UrlParser.map CoresPage (UrlParser.s "cores")
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



menu : Model -> Html Msg
menu model =
    div [ class "mb-4" ] [ 
      Navbar.config NavMsg
          |> Navbar.withAnimation
          |> Navbar.container
          |> Navbar.brand [ href "#" ] [ text "MiSTer" ]
          |> Navbar.items
              [ Navbar.itemLink [ ] (if model.waiting then [ Spinner.spinner [ ] [ ] ] else [])
              , Navbar.itemLink [ href "#cores" ] [ text "Cores" ]
              , Navbar.itemLink [ href "#games" ] [ text "Games" ]
              , Navbar.itemLink [ href "#modules" ] [ text "Settings" ]
              ]
          |> Navbar.view model.navState
    ]


mainContent : Model -> Html Msg
mainContent model =
    Grid.container [] <|
        case model.page of
            Home ->
                pageHome model

            GettingStarted ->
                pageGettingStarted model

            CoresPage ->
                pageCoresPage model

            NotFound ->
                pageNotFound


pageHome : Model -> List (Html Msg)
pageHome model =
    [ Grid.row []
        [ Grid.col []
            [ Card.config [ Card.outlinePrimary ]
                |> Card.headerH4 [] [ text "Getting started" ]
                |> Card.block []
                    [ Block.text [] [ text "Getting started is real easy. Just click the start button." ]
                    , Block.custom <|
                        Button.linkButton
                            [ Button.primary, Button.attrs [ href "#games" ] ]
                            [ text "Play" ]
                    ]
                |> Card.view
            ]
        , Grid.col []
            [ Card.config [ Card.outlineDanger ]
                |> Card.headerH4 [] [ text "Games" ]
                |> Card.block []
                    [ Block.text [] [ text "Check out the modules overview" ]
                    , Block.custom <|
                        Button.linkButton
                            [ Button.primary, Button.attrs [ href "#cores" ] ]
                            [ text "Game" ]
                    ]
                |> Card.view
            ]
        ]
    ]


pageGettingStarted : Model -> List (Html Msg)
pageGettingStarted model =
    [ h2 [] [ text "Getting started" ]
    , Button.button
        [ Button.success
        , Button.large
        , Button.block
        , Button.attrs [ onClick ScanCores ]
        ]
        [ text "Click me" ]
    ]


pageCoresPage : Model -> List (Html Msg)
pageCoresPage model =
    [ h1 [] [ text "Cores" ]
    ] ++ List.map toGameLauncher model.cores

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

module Main exposing (main)

import Html exposing (..)
import Http
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Url.Builder exposing (relative, crossOrigin, string, int)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Bootstrap.Navbar as Navbar
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Tab as Tab
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Utilities.Spacing as Spacing
import Bootstrap.Text as Text
import Bootstrap.Spinner as Spinner
import Json.Decode as D
import Dict exposing (Dict, get)
import List.Extra exposing (unique)


type PanelType =
      Info
    | Error

repository = "nilp0inter/MiSTer_WebMenu"
branch = "master"

staticData : (List String) -> String
staticData xs = crossOrigin "https://raw.githubusercontent.com" ([repository, branch, "static"] ++ xs) []

type alias Panel =
    { title : String
    , text : String
    , style : PanelType
    , visibility : Alert.Visibility
    }

apiRoot = ""

coreImages : Dict String String
coreImages  =
    Dict.fromList
        [ ("NES", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/NES-Console-Set.jpg/440px-NES-Console-Set.jpg")
        , ("Genesis", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Sega-Mega-Drive-JP-Mk1-Console-Set.jpg/500px-Sega-Mega-Drive-JP-Mk1-Console-Set.jpg")
        ]

type alias Core =
    { filename : String
    , codename : String
    , lpath : List String
    }

type alias Platform =
    { name : String
    , codename : List String
    }

coreDecoder : D.Decoder Core
coreDecoder =
  D.map3 Core
    (D.field "filename" D.string)
    (D.field "codename" D.string)
    (D.field "lpath" (D.list D.string))

platformDecoder : D.Decoder Platform
platformDecoder =
  D.map2 Platform
    (D.field "name" D.string)
    (D.field "codename" (D.list D.string))

type alias Flags =
    {}

type alias Model =
    { navKey : Navigation.Key
    , page : Page
    , coreFilter : Maybe String

    , navState : Navbar.State
    , tabState : Tab.State

    , modalVisibility : Modal.Visibility
    , modalTitle : String
    , modalBody : String
    , modalAction : Msg

    , messages : (List Panel)
    , cores : Maybe (List Core)
    , platforms : Maybe (List Platform)

    , waiting : Int
    , scanning : Bool
    }

type Page
    = AboutPage
    | CoresPage
    | SettingsPage
    | NotImplementedPage String String
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
                          , coreFilter = Nothing
                          , navState = navState
                          , tabState = Tab.initialState
                          , page = AboutPage
                          , modalVisibility = Modal.hidden
                          , modalTitle = ""
                          , modalBody = ""
                          , modalAction = CloseModal
                          , cores = Nothing
                          , platforms = Nothing
                          , waiting = 2  -- Per loadCores, loadPlatforms, ...
                          , scanning = False
                          , messages = [] }
    
    in
        ( model, Cmd.batch [ urlCmd, navCmd, loadCores, loadPlatforms ] )



type Msg
    = UrlChange Url
    | ClickedLink UrlRequest
    | NavMsg Navbar.State
    | TabMsg Tab.State
    | CloseModal
    | ShowModal String String Msg

    | LoadGame String String
    | GameLoaded (Result Http.Error ())

    | SyncFinished (Result Http.Error ())

    | LoadCores
    | ScanCores Bool
    | GotCores (Result Http.Error (Maybe (List Core)))
    | FilterCores String

    | GotPlatforms (Result Http.Error (Maybe (List Platform)))
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

        TabMsg state ->
            ( { model | tabState = state }
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

        ScanCores force ->
            ( { model | scanning = True
                      , waiting = model.waiting + 1 }, if model.scanning then Cmd.none else (syncCores force) )

        SyncFinished c ->
            case c of
                Ok cs -> ( { model | scanning = False }, loadCores )
                Err e -> ( { model | scanning = False
                                   , waiting = model.waiting - 1 
                                   , messages = (newPanel Error "Error scanning cores" (errorToString e)) :: model.messages }, Cmd.none )

        ClosePanel id vis ->
            ( { model | messages = (List.indexedMap (changePanelVisibility vis id) model.messages) }, Cmd.none )

        GotPlatforms p ->
            case p of
                Ok ps -> ( { model | waiting = model.waiting - 1, platforms = ps}, Cmd.none)
                Err e -> ( { model | waiting = model.waiting - 1, platforms = Nothing}, Cmd.none)

        FilterCores s ->
            if s == ""
            then ( { model | coreFilter = Nothing }, Cmd.none)
            else ( { model | coreFilter = Just s }, Cmd.none)


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

syncCores : Bool -> Cmd Msg
syncCores force =
    Http.get
      { url = relative ["api", "cores", "scan"] [ int "force" (if force then 1 else 0) ]
      , expect = Http.expectWhatever SyncFinished
      }

loadCores : Cmd Msg
loadCores =
    Http.get
      { url = relative ["cached", "cores.json"] [ ]
      , expect = Http.expectJson GotCores (D.nullable (D.list coreDecoder))
      }

loadPlatforms : Cmd Msg
loadPlatforms =
    Http.get
      { url = staticData ["platforms.json"]
      , expect = Http.expectJson GotPlatforms (D.nullable (D.list platformDecoder))
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
            ( { model | page = route
                      , coreFilter = Nothing }, Cmd.none )


decode : Url -> Maybe Page
decode url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
    |> UrlParser.parse routeParser


routeParser : Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map AboutPage top
        , UrlParser.map (NotImplementedPage "Games" "Search your game collection and play any rom with a single click.") (UrlParser.s "games")
        , UrlParser.map CoresPage (UrlParser.s "cores")
        , UrlParser.map (NotImplementedPage "Community" "View MiSTer news, and receive community updates and relevant content.") (UrlParser.s "community")
        , UrlParser.map SettingsPage (UrlParser.s "settings")
        , UrlParser.map AboutPage (UrlParser.s "about")
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
          |> Navbar.brand [ href "#about" ] [ text "MiSTer" ]
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
            AboutPage ->
                pageAboutPage model

            CoresPage ->
                pageCoresPage model

            SettingsPage ->
                pageSettingsPage model

            NotImplementedPage title description ->
                pageNotImplemented title description

            NotFound ->
                pageNotFound
    )

pageSettingsPage : Model -> List (Html Msg)
pageSettingsPage model =
    [ h1 [] [ text "Settings" ]
    , Card.config [ Card.outlineLight ]
        |> Card.block []
            [ Block.titleH2 [] [ text "Cores" ]
            , Block.text [] [ p [] [text "Click on 'Scan now' to start scanning for available cores in your MiSTer."],
                              p [] [text "This may take a couple of minutes depending on the number of files in your SD card."] ]
            , Block.custom <|
                Button.button [ Button.disabled model.scanning
                              , Button.primary
                              , Button.onClick (ScanCores True)
                 ] [ text "Scan now" ]
            ]
        |> Card.view ]

        

pageAboutPage : Model -> List (Html Msg)
pageAboutPage model =
    [ Grid.row []
        [ Grid.col []
            [ p [] [ text "Welcome to "
                   , strong [ ] [ text "MiSTer WebMenu" ]
                   , text ", a web interface for the MiSTer device."]
            , p [] [ text "This project is an early alpha, so expect some crashes here and there.  Please, report any crashes and/or desired feature through the project "
                   , a [ href "https://github.com/nilp0inter/MiSTer_WebMenu/issues"
                       , target "_blank" ] [ text "GitHub Issues" ]
                   , text " page."
                   ]
            , p [] [ text "Enjoy 😊" ]
            ]
        ]
    ]

pageNotImplemented : String -> String -> List (Html Msg)
pageNotImplemented title description = 
    [ h1 [] [ text title ]
    , p [] [ text description ]
    , Card.config [ Card.outlineInfo ]
        |> Card.block []
            [ Block.titleH3 [] [ text "Not implemented yet" ]
            , Block.text [] [ p [] [text "This feature will be available on future versions."] ]
            ]
        |> Card.view ]

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

-------------------------------------------------------------------------
--                                Cores                                --
-------------------------------------------------------------------------

pageCoresPage : Model -> List (Html Msg)
pageCoresPage model =
    case model.cores of
        Nothing ->
            case model.scanning of
                True -> waitForSync
                False -> coreSyncButton
        Just cs ->
            let
                filtered =
                    case model.coreFilter of
                        Nothing -> cs
                        Just s -> List.filter (matchCoreByString s) cs
                matches =
                    case model.coreFilter of
                        Nothing -> Nothing
                        Just _ -> Just (not (List.isEmpty filtered))
            in
                [ coreSearch matches
                , p [] [ text "Search your core collection and launch individual cores with a click." ]
                , coreTabs model filtered
                ]


coreSearch : Maybe Bool -> (Html Msg)
coreSearch match =
    let
        status =
            case match of
                Nothing -> []
                Just True -> [ Input.success ]
                Just False -> [ Input.danger ]
    in
        Grid.container [ class "mb-2" ]
            [ Grid.row []
                [ Grid.col [ Col.sm8 ] [ h1 [] [ text "Cores" ] ]
                , Grid.col [ Col.sm4
                           , Col.textAlign Text.alignXsRight ]
                      [ Form.form [ ]
                           [ Input.text ([ Input.attrs [ placeholder "Search"
                                                       , onInput FilterCores ]
                                         ] ++ status)
                           ]
                      ]
                ]
            ]

coreTabs : Model -> List Core -> Html Msg
coreTabs model cs =
    Tab.config TabMsg
        |> Tab.items (List.map (coreTab cs) (coreSections cs))
        |> Tab.view model.tabState

matchCoreByString : String -> Core -> Bool
matchCoreByString t c = String.contains (String.toLower t) (String.toLower c.codename)

coreSections : List Core -> List (List String)
coreSections cs = unique (List.map getLPath cs)

getLPath : Core -> List String
getLPath c = c.lpath

coreSelector : List Core -> Html Msg
coreSelector cs = Card.columns (List.map toGameLauncher cs)

coreTab : List Core -> List String -> (Tab.Item Msg)
coreTab cs path =
    let 
        filtered = (List.filter (isInPath path) cs)
    in 
        Tab.item
          { id = String.join "/" path
          , link = Tab.link [ ] [ text (String.join "/" path)
                                , Badge.pillLight [ Spacing.ml2 ] [ text (String.fromInt (List.length filtered)) ] ]
          , pane =
              Tab.pane [ Spacing.mt3 ]
                  [ Card.columns (List.map toGameLauncher filtered ) ]
          }


isInPath : List String -> Core -> Bool
isInPath p c = c.lpath == p


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
                              , Button.onClick (ScanCores False)
                 ] [ text "Scan now" ]
            ]
        |> Card.view
    ]


toGameLauncher : Core -> (Card.Config Msg)
toGameLauncher c = gameLauncher c.codename "" c.filename ""

gameLauncher : String -> String -> String -> String -> (Card.Config Msg)
gameLauncher title body core game =
    Card.config [ Card.outlineSecondary
                , Card.attrs [ ]
                , Card.align Text.alignXsCenter ]
        |> Card.header [] [ text title ]
        |> Card.imgTop [ src (
               case (get title coreImages) of
                   Nothing -> "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/1024px-No_image_available.svg.png"
                   Just s -> s ) ] []
        |> Card.block [  ] [ Block.quote [] [ p [] [ text body ] ]
                           ]
        |> Card.footer [ ] [
                Button.button [ Button.primary
                              , Button.onClick (ShowModal "Are you sure?" ("You are about to launch " ++ title ++ ". Any running game will be stopped immediately!") (LoadGame core game)) ] [ text "Play!" ]]
    


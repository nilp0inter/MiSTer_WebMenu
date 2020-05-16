port module Main exposing (main)

import Html exposing (..)
import Http
import Debug
import Bootstrap.CDN as CDN
import Bootstrap.CDN as CDN
import FontAwesome.Styles as Icon
import FontAwesome.Icon as Icon exposing (Icon)
import FontAwesome.Solid as Icon
import Process
import Html.Events exposing (on)
import Dict.Extra as DE
import Time
import Task
import Tree as T
import TreeView as TV
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Browser.Navigation as Navigation
import Browser exposing (UrlRequest)
import Url exposing (Url, percentEncode)
import Url.Builder exposing (relative, crossOrigin, string, int)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Bootstrap.Navbar as Navbar
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Pagination as Pagination
import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Breadcrumb as Breadcrumb
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Tab as Tab
import Bootstrap.Form as Form
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Utilities.Spacing as Spacing
import Bootstrap.Utilities.Display as Display
import Bootstrap.Text as Text
import Bootstrap.Spinner as Spinner
import Json.Decode as D
import Dict exposing (Dict, get)
import List.Extra exposing (unique, foldl1, foldr1, greedyGroupsOf, getAt, stripPrefix)

port reload : () -> Cmd msg

type Core =
      RBFCore RBF
    | MRACore MRA

coreBiMap : (MRA -> a) -> (RBF -> a) -> Core -> a
coreBiMap f g core =
    case core of
      MRACore c -> f c
      RBFCore c -> g c

cLpath = coreBiMap .lpath .lpath
cName = coreBiMap (\x -> x.filename |> String.dropRight 4) .codename
cFilename = coreBiMap .filename .filename
cPath = coreBiMap .path .path

type UpdateStatus =
      NotReady
    | GettingCurrent
    | ReadyToCheck
    | CheckingLatest
    | OnLatestRelease
    | UpdateAvailable
    | Updating
    | Updated
    | WaitingForReboot

type PanelType =
      Info
    | Error

user = "nilp0inter"
repository = "MiSTer_WebMenu"
branch = "master"

githubAPI : (List String) -> String
githubAPI xs = crossOrigin "https://api.github.com" (["repos", user, repository] ++ xs) []

staticData : (List String) -> String
staticData xs = crossOrigin "https://raw.githubusercontent.com" ([user, repository, branch, "static"] ++ xs) []

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
        , ("AY-3-8500", "https://upload.wikimedia.org/wikipedia/commons/3/35/AY-3-8500_DIL.jpg")
        , ("GBA", "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Nintendo-Game-Boy-Advance-Purple-FL.jpg/500px-Nintendo-Game-Boy-Advance-Purple-FL.jpg")
        , ("NeoGeo", "https://upload.wikimedia.org/wikipedia/en/thumb/f/f3/Neo_Geo_logo.svg/440px-Neo_Geo_logo.svg.png")
        , ("Astrocade", "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Bally-Arcade-Console.jpg/600px-Bally-Arcade-Console.jpg")
        , ("Gameboy", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Game-Boy-FL.jpg/500px-Game-Boy-FL.jpg")
        , ("Odyssey2", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Magnavox-Odyssey-2-Console-Set.jpg/600px-Magnavox-Odyssey-2-Console-Set.jpg")
        , ("Atari2600", "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Atari-2600-Wood-4Sw-Set.jpg/600px-Atari-2600-Wood-4Sw-Set.jpg")
        , ("SMS", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Sega-Master-System-Set.jpg/500px-Sega-Master-System-Set.jpg")
        , ("MegaCD", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Sega-CD-Model1-Set.jpg/500px-Sega-CD-Model1-Set.jpg")
        , ("SNES", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/SNES-Mod1-Console-Set.jpg/500px-SNES-Mod1-Console-Set.jpg")
        , ("Atari5200", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Atari-5200-4-Port-wController-L.jpg/600px-Atari-5200-4-Port-wController-L.jpg")
        , ("TurboGrafx16", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/TurboGrafx16-Console-Set.jpg/480px-TurboGrafx16-Console-Set.jpg")
        , ("ColecoVision", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/ColecoVision-wController-L.jpg/600px-ColecoVision-wController-L.jpg")
        , ("Vectrex", "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Vectrex-Console-Set.jpg/600px-Vectrex-Console-Set.jpg")
        --
        -- Computers
        --
        , ("Altair8800", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Altair_8800_Computer.jpg/600px-Altair_8800_Computer.jpg")
        , ("C64", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Commodore-64-Computer-FL.jpg/600px-Commodore-64-Computer-FL.jpg")
        , ("SharpMZ", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Sharp_MZ-700.jpg/440px-Sharp_MZ-700.jpg")
        , ("Amstrad", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Amstrad_CPC464.jpg/580px-Amstrad_CPC464.jpg")
        , ("Jupiter", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Jupiter_ACE_%28restored%29.JPG/500px-Jupiter_ACE_%28restored%29.JPG")
        , ("Apogee", "https://upload.wikimedia.org/wikipedia/ru/thumb/c/c2/Apogei-bk01.jpg/274px-Apogei-bk01.jpg")
        , ("Minimig", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Amiga500_system.jpg/600px-Amiga500_system.jpg")
        , ("QL", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Sinclair_QL_Top.jpg/600px-Sinclair_QL_Top.jpg")
        , ("ht1080z", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Radioshack_TRS80-IMG_7206.jpg/560px-Radioshack_TRS80-IMG_7206.jpg")
        , ("MSX", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Sony_HitBit_HB-10P_%28White_Background%29.jpg/440px-Sony_HitBit_HB-10P_%28White_Background%29.jpg")
        , ("MacPlus", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Macintosh822014.JPG/600px-Macintosh822014.JPG")
        , ("Ti994a", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/TI99-IMG_7132_%28filter_levels_crop%29.jpg/600px-TI99-IMG_7132_%28filter_levels_crop%29.jpg")
        , ("Apple-II", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Apple_II_typical_configuration_1977.png/600px-Apple_II_typical_configuration_1977.png")
        , ("VIC20", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Commodore-VIC-20-FL.jpg/600px-Commodore-VIC-20-FL.jpg")
        , ("Apple-I", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Apple_1_Woz_1976_at_CHM.agr_cropped.jpg/600px-Apple_1_Woz_1976_at_CHM.agr_cropped.jpg")
        , ("Vector-06C", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Vector-06c.JPG/640px-Vector-06c.JPG")
        , ("Archie", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/AcornArchimedes-Wiki.jpg/600px-AcornArchimedes-Wiki.jpg")
        , ("Aquarius", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Mattel-Aquarius-Computer-FL.jpg/600px-Mattel-Aquarius-Computer-FL.jpg")
        , ("ORAO", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Orao-IMG_7278.jpg/600px-Orao-IMG_7278.jpg")
        , ("X68000", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/X68000ACE-HD.JPG/400px-X68000ACE-HD.JPG")
        , ("Oric", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Oric1.jpg/400px-Oric1.jpg")
        , ("ZX-Spectrum", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/ZXSpectrum48k.jpg/600px-ZXSpectrum48k.jpg")
        , ("BK0011M", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Bk0010-01-sideview.jpg/640px-Bk0010-01-sideview.jpg")
        , ("Atari800", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Atari-800-Computer-FL.jpg/600px-Atari-800-Computer-FL.jpg")
        , ("PDP1", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Steve_Russell_and_PDP-1.png/440px-Steve_Russell_and_PDP-1.png")
        , ("ZX81", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Sinclair-ZX81.png/600px-Sinclair-ZX81.png")
        , ("BBCMicro", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/BBC_Micro_Front_Restored.jpg/600px-BBC_Micro_Front_Restored.jpg")
        , ("PET2001", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Commodore_2001_Series-IMG_0448b.jpg/560px-Commodore_2001_Series-IMG_0448b.jpg")
        , ("ao486", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Intel_i486_DX_25MHz_SX328.jpg/1024px-Intel_i486_DX_25MHz_SX328.jpg")
        , ("C16", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Commodore_16_002a.png/600px-Commodore_16_002a.png")
        , ("SAMCoupe", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/SAM_Coup%C3%A9.jpg/600px-SAM_Coup%C3%A9.jpg")
        ]

type alias RBF =
    { filename : String
    , codename : String
    , lpath : List String
    , path : String
    }

type alias Rom =
    { zip : String
    }

type alias MRA =
    { path : String
    , filename : String
    , name : String
    , lpath : List String
    , md5 : String
    , roms : List Rom
    , romsFound : Bool
    }

type alias Platform =
    { name : String
    , codename : List String
    }

romDecoder : D.Decoder Rom
romDecoder =
  (D.map Rom (D.field "zip" D.string))

rbfDecoder : D.Decoder RBF
rbfDecoder =
  (D.map4 (RBF)
     (D.field "filename" D.string)
     (D.field "codename" D.string)
     (D.field "lpath" (D.list D.string))
     (D.field "path" D.string))

mraDecoder : D.Decoder MRA
mraDecoder =
  (D.map7 MRA
     (D.field "path" D.string)
     (D.field "filename" D.string)
     (D.field "name" D.string)
     (D.field "lpath" (D.list D.string))
     (D.field "md5" D.string)
     (D.field "roms" (D.map (Maybe.withDefault []) (D.nullable (D.list romDecoder))))
     (D.field "roms_found" D.bool))

coreDecoder : D.Decoder (List Core)
coreDecoder =
     -- (D.field "rbfs" (D.list (D.map RBFCore rbfDecoder)))
  (D.map2 (++)
     (D.field "rbfs" (D.list (D.map RBFCore rbfDecoder)))
     (D.field "mras" (D.list (D.map MRACore mraDecoder))))

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

    , modalVisibility : Modal.Visibility
    , modalTitle : String
    , modalBody : String
    , modalAction : Msg

    , messages : (List Panel)
    , cores : Maybe (List Core)
    , platforms : Maybe (List Platform)

    , waiting : Int
    , scanning : Bool

    , currentVersion : String
    , latestRelease : String
    , updateStatus : UpdateStatus

    , missingThumbnails : List String
    , currentPath : List String

    , treeViewModel : TV.Model CoreFolder String Never ()
    , selectedCoreFolder : Maybe CoreFolder
    , activePageIdx : Int
    , selectedCore : Maybe Core
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

type alias CoreFolder = { label : String
                        , content : List Core
                        , path : List String}

init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate url { navKey = key
                          , coreFilter = Nothing
                          , navState = navState
                          , page = AboutPage
                          , modalVisibility = Modal.hidden
                          , modalTitle = ""
                          , modalBody = ""
                          , modalAction = CloseModal
                          , cores = Nothing
                          , platforms = Nothing
                          , waiting = 3  -- Per loadCores, loadPlatforms, ...
                          , scanning = False
                          , messages = []

                          , currentVersion = ""
                          , latestRelease = ""
                          , updateStatus = NotReady
                          , missingThumbnails = []
                          , currentPath = []
                          , treeViewModel = TV.initializeModel configuration []
                          , selectedCoreFolder = Nothing
                          , activePageIdx = 0
                          , selectedCore = Nothing
                          }
    
    in
        ( model, Cmd.batch [ urlCmd
                           , navCmd
                           , loadCores
                           , loadPlatforms
                           , checkCurrentVersion ] )



type Msg
    = UrlChange Url
    | ClickedLink UrlRequest
    | NavMsg Navbar.State
    | CloseModal
    | ShowModal String String Msg

    | LoadGame String String String
    | GameLoaded (Result Http.Error ())

    | SyncFinished (Result Http.Error ())

    | LoadCores
    | ScanCores Bool
    | GotCores (Result Http.Error (Maybe (List Core)))
    | FilterCores String

    | GotPlatforms (Result Http.Error (Maybe (List Platform)))
    | ClosePanel Int Alert.Visibility

    | GotCurrentVersion (Result Http.Error String)

    | CheckLatestRelease
    | GotLatestRelease (Result Http.Error (List (Maybe String)))

    | Update String
    | GotUpdateResult (Result Http.Error ())

    | GotReboot (Result Http.Error ())
    | GotNewVersion (Result Http.Error String)
    | Reload

    | MissingThumbnail String
    | TreeViewMsg (TV.Msg String)
    | PaginationMsg Int
    | SelectCore (Maybe Core)

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navbar.subscriptions model.navState NavMsg
        , Sub.map TreeViewMsg (TV.subscriptions model.treeViewModel)
        ]


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

        LoadGame core game lpath ->
            ( { model | modalVisibility = Modal.hidden }, loadGame core game lpath )

        GameLoaded _ ->
            ( model, Cmd.none )

        LoadCores ->
            ( { model | waiting = model.waiting + 1 }, loadCores )

        GotCores c ->
            case c of
                Ok cs ->
                    let
                       (treeModel, _) =
                           TV.expandOnly (firstLevel) <| TV.initializeModel configuration (buildNodes <| Maybe.withDefault [] cs)
                    in
                       ( { model | waiting = model.waiting - 1
                                  , treeViewModel = treeModel
                                  , cores = cs
                                  }
                        , Cmd.none )
                Err (Http.BadStatus 404) -> ( { model | waiting = model.waiting-1, cores = Nothing }, Cmd.none )
                Err e -> ( { model | waiting = model.waiting - 1
                                   , messages = (newPanel Error "Error parsing cores" (errorToString e)) :: model.messages  }, Cmd.none )

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
            then let
                       (treeModel, _) =
                           TV.expandOnly (firstLevel) (TV.collapseAll model.treeViewModel)
                 in
                       ( { model | coreFilter = Nothing
                              , treeViewModel = treeModel
                              , activePageIdx = 0
                              }
                       , Cmd.none)
            else let
                       (treeModel, highlit) =
                           TV.expandOnly (matchCoreFolder s) model.treeViewModel
                 in
                       ( { model | coreFilter = Just s
                                 , activePageIdx = 0
                                 , treeViewModel = treeModel  }
                        , Cmd.none)


        GotCurrentVersion x ->
            case x of
                Ok v -> ( { model | waiting = model.waiting - 1
                                  , currentVersion = v }, Cmd.none)
                Err e -> ( { model | waiting = model.waiting - 1
                                   , messages = (newPanel Error "Error retrieving current version" (errorToString e)) :: model.messages }, Cmd.none )

        CheckLatestRelease ->
            ( { model | updateStatus = CheckingLatest
                      , waiting = model.waiting + 1 }
              , checkLatestRelease )

        GotLatestRelease x ->
            case x of
                Ok v ->
                    let
                        latest = (List.foldr (firstJust) Nothing v)
                    in
                        case latest of
                            Nothing ->
                                ( { model | waiting = model.waiting - 1
                                          , updateStatus = OnLatestRelease }
                                , Cmd.none)
                            Just l ->
                                ( { model | waiting = model.waiting - 1
                                          , latestRelease = l
                                          , updateStatus = if l == model.currentVersion
                                                           then OnLatestRelease
                                                           else UpdateAvailable
                                  }
                                , Cmd.none)
                Err e -> ( { model | waiting = model.waiting - 1
                                   , messages = (newPanel Error "Error checking latest release" (errorToString e)) :: model.messages
                                   , updateStatus = ReadyToCheck }
                           , Cmd.none)

        Update v ->
            ( { model | updateStatus = Updating
                      , waiting = model.waiting + 1 }
            , updateToRelease v )

        GotUpdateResult x ->
            case x of
                Ok _ ->  ( model, rebootBackend )
                Err e -> ( { model | waiting = model.waiting - 1
                                   , updateStatus = UpdateAvailable
                                   , messages = (newPanel Error "Error updating WebMenu :(" (errorToString e)) :: model.messages }
                           , Cmd.none )

        Reload -> ( model, reload ())

        GotReboot x ->
            case x of
                Ok _ -> ( model, checkNewVersion )
                Err _ ->  ( model, rebootBackend )
          
        GotNewVersion x ->
            case x of
                Ok v -> if v /= model.currentVersion
                        then ( { model | waiting = model.waiting - 1
                                       , updateStatus = WaitingForReboot
                                       , modalVisibility = Modal.shown
                                       , modalTitle = "Updated Successfully!"
                                       , modalBody = "Click to finish the installation."
                                       , modalAction = Reload }, Cmd.none )
                        else (model, checkNewVersion)
                Err _ ->  (model, checkNewVersion)

        MissingThumbnail x ->
            ( { model | missingThumbnails = (x::model.missingThumbnails) }
            , Cmd.none)

        TreeViewMsg tvm ->
            let
                treeView = TV.update tvm model.treeViewModel
            in
            ( { model | treeViewModel = treeView
                      , activePageIdx = 0
                      , selectedCoreFolder = TV.getSelected treeView |> Maybe.map .node |> Maybe.map T.dataOf }
            , Cmd.none)

        PaginationMsg i ->
            ( { model | activePageIdx = i
              }
            , Cmd.none )

        SelectCore mc ->
            ( { model | selectedCore = mc }
            , Cmd.none )


firstLevel : CoreFolder -> Bool
firstLevel cf = (List.length cf.path) == 1

matchCoreFolder : String -> CoreFolder -> Bool
matchCoreFolder st cf = String.contains st cf.label || List.any (cName >> String.toLower >> String.contains st) cf.content

firstJust : Maybe a -> Maybe a -> Maybe a
firstJust l r =
    case l of
        Nothing -> r
        Just x -> Just x

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

rebootBackend : Cmd Msg
rebootBackend =
    Task.attempt GotReboot
    (Http.task
       { method = "POST"
       , headers = []
       , url = relative ["api", "webmenu", "reboot"] []
       , body = Http.emptyBody
       , timeout = Nothing
       , resolver = Http.stringResolver <| ignoreResolver
       })

ignoreResolver : Http.Response String -> Result Http.Error ()
ignoreResolver response =
    case response of
        Http.GoodStatus_ _ body -> Ok ()
        x -> Err Http.Timeout

checkCurrentVersion : Cmd Msg
checkCurrentVersion =
    Http.get
      { url = relative ["api", "version", "current"] []
      , expect = Http.expectString GotCurrentVersion
      }

checkNewVersion : Cmd Msg
checkNewVersion =
    Task.attempt GotNewVersion
    (
      Process.sleep 3000
        |> Task.andThen (\_ ->
               (Http.task
                  { method = "GET"
                  , headers = []
                  , url = relative ["api", "version", "current"] []
                  , body = Http.emptyBody
                  , timeout = Nothing
                  , resolver = Http.stringResolver <| passStringResolver
                  }))
    )

passStringResolver : Http.Response String -> Result Http.Error String
passStringResolver response =
    case response of
        Http.GoodStatus_ _ body -> Ok body
        x -> Err Http.Timeout

decodeReleases : D.Decoder (List (Maybe String))
decodeReleases =
    D.list
       (D.map3
           decodeStable
           (D.field "tag_name" D.string)
           (D.field "draft" D.bool)
           (D.field "prerelease" D.bool))

checkLatestRelease : Cmd Msg
checkLatestRelease =
    Http.get
      { url = githubAPI ["releases"]
      , expect = Http.expectJson GotLatestRelease decodeReleases
      }

updateToRelease : String -> Cmd Msg
updateToRelease v =
    Http.post
      { url = relative ["api", "update"] [ string "version" v ]
      , body = Http.emptyBody
      , expect = Http.expectWhatever GotUpdateResult
      }

decodeStable : String -> Bool -> Bool -> Maybe String
decodeStable tag draft prerelease =
    if draft || prerelease
    then Nothing
    else Just tag

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
      , expect = Http.expectJson GotCores (D.nullable coreDecoder)
      }

loadPlatforms : Cmd Msg
loadPlatforms =
    Http.get
      { url = staticData ["platforms.json"]
      , expect = Http.expectJson GotPlatforms (D.nullable (D.list platformDecoder))
      }

loadGame : String -> String -> String -> Cmd Msg
loadGame core game lpath =
    Http.get
      { url = relative ["api", "run"] [ string "path" lpath ]
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
        [ UrlParser.map AboutPage top
        , UrlParser.map (NotImplementedPage "Games" "Search your game collection and play any ROM with a single click") (UrlParser.s "games")
        , UrlParser.map CoresPage (UrlParser.s "cores")
        , UrlParser.map (NotImplementedPage "Community" "View MiSTer news, and receive community updates and relevant content") (UrlParser.s "community")
        , UrlParser.map SettingsPage (UrlParser.s "settings")
        , UrlParser.map AboutPage (UrlParser.s "about")
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "MiSTer WebMenu"
    , body =
        [ div []
            [ CDN.stylesheet -- creates an inline style node with the Bootstrap CSS
            , Icon.css
            , menu model
            , mainContent model
            , modal model
            ]
        ]
    }

messages : Model -> Html Msg
messages model = 
    div [ class "mb-1" ] [
        Grid.row []
            [ Grid.col [] (List.indexedMap showPanel model.messages) ] ]

showPanel : Int -> Panel -> Html Msg
showPanel id panel = 
    Alert.config
        |> Alert.dismissableWithAnimation (ClosePanel id)
        |> (case panel.style of
                Info -> Alert.info
                Error -> Alert.danger
           )
        |> Alert.children
            [ Alert.h4 [] [ text panel.title ]
            , p [] [ text panel.text ]
            ]
        |> Alert.view panel.visibility

menu : Model -> Html Msg
menu model =
    div [ class "mb-2" ] [ 
      Navbar.config NavMsg
          |> Navbar.withAnimation
          |> Navbar.dark
          |> Navbar.collapseSmall
          |> Navbar.container
          |> Navbar.brand [ class "text-white" ] [ strong [] [ text "MiSTer" ] ]
          |> Navbar.items
              [ Navbar.itemLink [ href "#cores" ] [ text "Cores" ]
              , Navbar.itemLink [ href "#games" ] [ text "Games" ]
              , Navbar.itemLink [ href "#community" ] [ text "Community" ]
              , Navbar.itemLink [ href "#settings" ] [ text "Settings" ]
              , Navbar.itemLink [ href "#about" ] [ text "About" ]
              ]
          |> Navbar.customItems
              [ Navbar.customItem (if model.waiting > 0 then ( Spinner.spinner [ Spinner.grow
                , Spinner.color Text.light ] [ ] ) else ( text "" ) )
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

sectionHeading : String -> String -> (Html Msg)
sectionHeading title motto =
    Grid.container []
        [ Grid.row []
            [ Grid.col [] [ h1 [ class "display-4" ] [ text title ]
                          , p [ class "lead" ] [ text motto ]
                          ]
            ]
        ]

           
pageSettingsPage : Model -> List (Html Msg)
pageSettingsPage model =
    [ sectionHeading "Settings" "WebMenu and MiSTer configuration"
    , Card.deck
      [ Card.config [ Card.outlineLight ]
          |> Card.block [] (scanCoresBlock model)
      , Card.config [ Card.outlineLight ]
          |> Card.block [] (checkForUpdatesBlock model)
          |> Card.block [] (
                 case model.updateStatus of
                     UpdateAvailable -> (updateAvailableBlock model)
                     OnLatestRelease -> (onLatestReleaseBlock model)
                     Updating -> (updateAvailableBlock model)
                     WaitingForReboot -> (updateAvailableBlock model)
                     _ -> [] )
      ]
    ]

scanCoresBlock model =
    [ Block.titleH2 [] [ text "Cores" ]
    , Block.text [] [ p [] [text "Click on 'Scan now' to start scanning for available cores in your MiSTer."],
                      p [] [text "This may take a couple of minutes depending on the number of files in your SD card."] ]
    , Block.custom <|
        Button.button [ Button.disabled model.scanning
                      , Button.primary
                      , Button.onClick (ScanCores True)
         ] [ text "Scan now" ]
    ]

checkForUpdatesBlock model =
    [ Block.titleH2 [] [ text "WebMenu Update" ]
    , Block.text [] [ p [] [ text "Check for new releases of WebMenu."]
                    , p [] [ text "You are currently running "
                           , strong [] [ text model.currentVersion ]
                           ]
                    ]
    , Block.custom
          <| Button.button [ Button.disabled (model.updateStatus == ReadyToCheck)
                           , Button.info
                           , Button.onClick CheckLatestRelease
                           ] [ text "Check for updates" ]
    ]

onLatestReleaseBlock model = 
    [ Block.text [] [ strong [] [ text "You are up to date!" ] ] ]

updateAvailableBlock model = 
    [ Block.titleH3 [] [ text "Update Available!" ]
    , Block.text [] [ p [] [ text "The latest release is "
                           , strong [] [ text model.latestRelease ]
                           ]
                    ]
    , Block.custom
          <| Button.button [ Button.disabled (model.updateStatus /= UpdateAvailable)
                           , Button.warning
                           , Button.onClick (Update model.latestRelease)
                           ] [ text "Update!" ]
    ]

pageAboutPage : Model -> List (Html Msg)
pageAboutPage model =
    [ Grid.row [  ]
        [ Grid.col []
            [ h1 [ class "mt-4" ] [ text "Welcome to WebMenu!\n" 
                     , br [] []
                     , small [ class "text-muted", class "lead" ] [ text "A web interface for MiSTer" ] ]
            , p [] [ text "This project is an early alpha, so expect some rough edges." ]
            , p [] [ text "Please, report any problems and/or desired feature through the project " 
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
    [ sectionHeading title description 
    , Card.config [  ]
        |> Card.block []
            [ Block.titleH3 [] [ text "Not implemented yet" ]
            , Block.text [] [ p [ ] [text "This feature will be available on future versions."] ]
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
        |> Modal.body [] [ text model.modalBody ]
        |> Modal.footer [] [ Button.button [ Button.warning, Button.onClick model.modalAction ] [ text "Proceed" ] ]
        |> Modal.view model.modalVisibility

-------------------------------------------------------------------------
--                                Cores                                --
-------------------------------------------------------------------------

pageCoresPage : Model -> List (Html Msg)
pageCoresPage model = [ sectionHeading "Cores" "Search your core collection and launch individual cores with a click" 
                      , pageCoresPageContent model ]

pageCoresPageContent : Model -> Html Msg
pageCoresPageContent model =
    case model.cores of
        Nothing ->
            case model.scanning of
                True -> waitForSync
                False -> coreSyncButton
        Just cs ->
            let
                filteredBySearch =
                    case model.coreFilter of
                        Nothing -> cs
                        Just s -> List.filter (matchCoreByString s) cs
                filtered =
                    case model.selectedCoreFolder of
                        Nothing -> filteredBySearch
                        Just cf -> List.filter (filterByNode cf) filteredBySearch
                pages = greedyGroupsOf 90 (List.sortBy cLpath filtered)
                selectedPage = Maybe.withDefault [ ] (getAt model.activePageIdx pages)
                activePagination = List.length pages > 1
                paginationBlock = (if activePagination
                                  then [ simplePaginationList pages model ]
                                  else [])
                pageWithSections = selectedPage |> DE.groupBy cLpath |> Dict.toList

            in
                Grid.container []
                    [ Grid.row []
                        [ Grid.col [ Col.sm3 ] [ coreSearch model
                                               , Html.map TreeViewMsg (TV.view model.treeViewModel) ]
                        , Grid.col [ Col.sm9 ] (paginationBlock ++ (List.concat <| List.map (coreFolderContent model) pageWithSections) ++ paginationBlock)
                        ]
                    ]

simplePaginationList : List (List Core) -> Model -> Html Msg
simplePaginationList pages model =
    Pagination.defaultConfig
        |> Pagination.ariaLabel "Pagination"
        |> Pagination.small
        |> Pagination.align HAlign.centerXs
        |> Pagination.itemsList
            { selectedMsg = PaginationMsg
            , prevItem = Just <| Pagination.ListItem [] [ text "<<" ]
            , nextItem = Just <| Pagination.ListItem [] [ text ">>" ]
            , activeIdx = model.activePageIdx
            , data = List.range 1 (List.length pages)
            , itemFn = \idx pcs -> Pagination.ListItem [] [ text (String.fromInt pcs) ]
            , urlFn = \idx _ -> "#cores"
            }
        |> Pagination.view

filterByNode : CoreFolder -> Core -> Bool
filterByNode cf c =
    let
        realPath = Maybe.withDefault [] (List.tail cf.path |> Maybe.map (\xs -> xs ++ [cf.label]))
    in
        case stripPrefix realPath (cLpath c) of
             Nothing -> False
             Just _ -> True

nodeLabel : T.Node CoreFolder -> String
nodeLabel (T.Node node) = node.data.label

nodeUid : T.Node CoreFolder -> TV.NodeUid String
nodeUid (T.Node node) = TV.NodeUid <| (String.join "/" node.data.path) ++ node.data.label

singleton : List String -> String -> List Core -> T.Node CoreFolder
singleton p x cs = T.Node {data={label=x, path=p, content=cs}, children=[]}


treeFromList : List String -> List String -> List Core -> Maybe (T.Node CoreFolder)
treeFromList p ss cs = 
    case ss of 
        [] -> Nothing
        [x] -> Just <| T.Node { data={label=x, path=p, content=cs}
                              , children=[] }
        (x::xs) -> Just <| T.Node { data={label=x, path=p, content=[]}
                                  , children=Maybe.withDefault [] (Maybe.map List.singleton (treeFromList (p++[x]) xs cs))}

configuration : TV.Configuration CoreFolder String
configuration =
    TV.Configuration
        nodeUid  -- to construct node UIDs
        nodeLabel  -- to render node (data) to text
        TV.defaultCssClasses  -- CSS classes to use

buildNodes : List Core -> List (T.Node CoreFolder)
buildNodes cs = cs |> DE.groupBy (\x -> ["SD Card"] ++ (cLpath x))
                   |> Dict.toList
                   |> List.reverse
                   |> List.filterMap (\(ss, cc) -> treeFromList [] ss cc)
                   |> List.foldl (mergeForest) []

getMatching : CoreFolder -> List (T.Node CoreFolder) -> List (T.Node CoreFolder) -> Maybe (T.Node CoreFolder, List (T.Node CoreFolder))
getMatching l prev post =
    case post of
        [] -> Nothing
        (x::xs2) ->
            if (T.dataOf x).label == l.label && (T.dataOf x).path == l.path
            then Just (x, prev ++ xs2)
            else getMatching l (prev++[x]) xs2

mergeForest : T.Node CoreFolder -> List (T.Node CoreFolder) -> List (T.Node CoreFolder)
mergeForest l xs =
    let
        y = (T.dataOf l)
        ys = T.childrenOf l
    in
        case getMatching y [] xs of
            Nothing -> (l::xs)
            Just (x, xs2) -> (mergeAdding x l) ++ xs2
    
mergeFolder : CoreFolder -> CoreFolder -> CoreFolder
mergeFolder f1 f2 =
    { label = f1.label
    , path = f1.path
    , content = f1.content ++ f2.content }

toNode : CoreFolder -> List (T.Node CoreFolder) -> T.Node CoreFolder
toNode d c = T.Node {data=d, children=c}
  
mergeAdding : T.Node CoreFolder -> T.Node CoreFolder -> List (T.Node CoreFolder )
mergeAdding l r =
    let
        x = (T.dataOf l)
        xs = T.childrenOf l
        y = (T.dataOf r)
        ys = T.childrenOf r
    in
        if x.label == y.label && x.path == y.path
        then [toNode (mergeFolder x y) (List.foldl (mergeForest) xs ys)]
        else [toNode x xs, toNode y ys]

coreSearch : Model -> Html Msg
coreSearch model =
    Form.form [ class "mb-4" ]
       [ InputGroup.config
             (InputGroup.text [ Input.attrs [ onInput FilterCores ] ])
             |> InputGroup.predecessors
                 [ InputGroup.span [ ] [ span [] [ Icon.viewIcon Icon.search ] ] ]
             |> InputGroup.view
       ]

matchCoreByString : String -> Core -> Bool
matchCoreByString t c =
   case c of
       RBFCore r -> String.contains (String.toLower t) (String.toLower r.codename)
       MRACore m -> String.contains (String.toLower t) (String.toLower m.name) || String.contains (String.toLower t) (String.toLower m.filename)

partition : Int -> a -> List a -> List (List a)
partition n d xs =
    if List.isEmpty xs
    then []
    else (List.take n (xs ++ (List.repeat n d))) :: (partition n d (List.drop n xs))


brFromPath : List String -> Html Msg
brFromPath ps =
    Breadcrumb.container <|
        List.map (\x -> Breadcrumb.item [] [ text x ]) ps

coreFolderContent : Model -> (List String, List Core) -> List (Html Msg)
coreFolderContent m (path, cs) = [ brFromPath path ] ++ coreContent m cs

coreContent : Model -> List Core -> List (Html Msg)
coreContent m cs = List.map Card.deck (partition 3 emptyCard (List.map (coreCard m) cs))

emptyCard =
    Card.config [ Card.outlineSecondary
                , Card.attrs [ class "emptycard" ] ]

waitForSync : Html Msg
waitForSync =
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

coreSyncButton : Html Msg
coreSyncButton =
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

cardBadge : (List (Attribute msg) -> List (Html Msg) -> Html Msg) -> String -> Html Msg
cardBadge bdColor s = bdColor [ Spacing.ml1 ] [ text s ]

rbfCardBlock : RBF -> Block.Item Msg
rbfCardBlock m =
    Block.text [] [ cardBadge (Badge.badgeDark) "RBF" ]

mraCardBlock : MRA -> Block.Item Msg
mraCardBlock m =
    Block.text [] [ cardBadge (Badge.badgeDark) "MRA"
                  , if m.romsFound
                    then cardBadge (Badge.badgeSuccess) "ROM Found"
                    else cardBadge (Badge.badgeWarning) "ROM Missing"
                  ]

ifNotMissing : Model -> String -> String
ifNotMissing m s = if List.member s m.missingThumbnails then "" else s

rbfImgTop : RBF -> String
rbfImgTop r = Maybe.withDefault "" <| get r.codename coreImages

mraImgTop : MRA -> String
mraImgTop m = crossOrigin "https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles" [(percentEncode m.name) ++ ".png"] []


coreCard : Model -> Core -> (Card.Config Msg)
coreCard model core =
    let
        bimap = coreBiMap
        title = cName core
        imgSrc = ifNotMissing model <| bimap mraImgTop rbfImgTop core
        body = bimap mraCardBlock rbfCardBlock core
        thumbnail =
            if imgSrc == ""
            then Card.block [ Block.attrs [ class "text-muted", class "d-flex", class "justify-content-center", class "align-items-center", class "corenoimg" ] ]
                            [ Block.text [] [ text "No image available" ] ]
            else Card.imgTop [ src imgSrc, on "error" (D.succeed (MissingThumbnail imgSrc)) ] []
        
        corePath = cFilename core
        game = ""
        path = cPath core
        loadEv = ShowModal "Are you sure?" ("You are about to launch " ++ title ++ ". Any running game will be stopped immediately!") (LoadGame corePath game path)
        selected = if model.selectedCore == Just core
                   then [ Block.light ]
                   else []
    in
        Card.config [ Card.outlineSecondary
                    , Card.attrs [ Spacing.mb4
                                 , on "mouseenter" (D.succeed (SelectCore <| Just core))
                                 , on "mouseleave" (D.succeed (SelectCore Nothing))
                                 ] ]
            |> Card.header [ class "text-center" ] [ text title ]
            |> thumbnail
            |> Card.block ([ Block.attrs [ class "d-flex"
                                         , class "align-content-end"
                                         , class "flex-row"
                                         , class "flex-wrap" ] ] ++ selected)
                          [ body ]
            |> Card.footer [ class "bg-primary"
                           , class "text-center"
                           , class "text-white"
                           , class "runbutton"
                           , on "click" (D.succeed (loadEv)) ] [ text "Run" ]
                           

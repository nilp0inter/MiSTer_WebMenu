port module Main exposing (main)

import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Breadcrumb as Breadcrumb
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Fieldset as Fieldset
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Pagination as Pagination
import Bootstrap.Spinner as Spinner
import Bootstrap.Text as Text
import Bootstrap.Utilities.Flex as Flex
import Bootstrap.Utilities.Spacing as Spacing
import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Debug
import Dict exposing (Dict, get)
import Dict.Extra as DE
import FontAwesome.Icon as Icon exposing (Icon)
import FontAwesome.Solid as Icon
import FontAwesome.Styles as Icon
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput)
import Html.Keyed as Keyed
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import List.Extra exposing (getAt, greedyGroupsOf, last, stripPrefix)
import Process
import Result.Extra
import Set as Set
import Task
import Tree as T
import TreeView as TV
import Url exposing (Url, percentEncode)
import Url.Builder exposing (crossOrigin, int, relative, string)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)


port reload : () -> Cmd msg


type Core
    = RBFCore RBF
    | MRACore MRA


coreBiMap : (MRA -> a) -> (RBF -> a) -> Core -> a
coreBiMap f g core =
    case core of
        MRACore c ->
            f c

        RBFCore c ->
            g c


cLpath =
    coreBiMap .lpath .lpath


cName =
    coreBiMap (\x -> x.filename |> String.dropRight 4) .codename


cFilename =
    coreBiMap .filename .filename


cPath =
    coreBiMap .path .path


type UpdateStatus
    = NotReady
    | GettingCurrent
    | ReadyToCheck
    | CheckingLatest
    | OnLatestRelease
    | UpdateAvailable
    | Updating
    | Updated
    | WaitingForReboot


type PanelType
    = Info
    | Error


user =
    "nilp0inter"


repository =
    "MiSTer_WebMenu"


branch =
    "master"


githubAPI : List String -> String
githubAPI xs =
    crossOrigin "https://api.github.com" ([ "repos", user, repository ] ++ xs) []


staticData : List String -> String
staticData xs =
    crossOrigin "https://raw.githubusercontent.com" ([ user, repository, branch, "static" ] ++ xs) []


type alias Panel =
    { title : String
    , text : String
    , style : PanelType
    , visibility : Alert.Visibility
    }


apiRoot =
    ""


systemToCoreCodename : Dict String String
systemToCoreCodename =
    Dict.fromList
        [ ( "Sinclair - ZX Spectrum", "ZX-Spectrum" )
        , ( "Atari - 2600", "Atari2600" )

        -- , ( "Atari - 5200", "Atari5200" )  -- TODO: FIX UNKNOWN
        -- CARTRIDGE TYPE
        , ( "Sega - Mega Drive - Genesis", "Genesis" )
        , ( "Nintendo - Nintendo Entertainment System", "NES" )
        , ( "Nintendo - Super Nintendo Entertainment System", "SNES" )
        , ( "Nintendo - Game Boy Advance", "GBA" )
        , ( "Nintendo - Game Boy", "Gameboy" )
        , ( "Nintendo - Game Boy Color", "Gameboy" )
        , ( "NEC - PC Engine - TurboGrafx 16", "TurboGrafx16" )
        , ( "Amstrad - CPC", "Amstrad" )
        , ( "Coleco - ColecoVision", "ColecoVision" )
        , ( "Magnavox - Odyssey2", "Odyssey2" )
        , ( "Sega - Game Gear", "SMS" )
        , ( "Sega - Master System - Mark III", "SMS" )
        , ( "Sega - SG-1000", "ColecoVision" )

        -- , ( "NEC - PC Engine CD - TurboGrafx-CD", "TurboGrafx16" )
        ]


coreImages : Dict String String
coreImages =
    Dict.fromList
        [ ( "NES", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/NES-Console-Set.jpg/440px-NES-Console-Set.jpg" )
        , ( "Genesis", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Sega-Mega-Drive-JP-Mk1-Console-Set.jpg/500px-Sega-Mega-Drive-JP-Mk1-Console-Set.jpg" )
        , ( "AY-3-8500", "https://upload.wikimedia.org/wikipedia/commons/3/35/AY-3-8500_DIL.jpg" )
        , ( "GBA", "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Nintendo-Game-Boy-Advance-Purple-FL.jpg/500px-Nintendo-Game-Boy-Advance-Purple-FL.jpg" )
        , ( "NeoGeo", "https://upload.wikimedia.org/wikipedia/en/thumb/f/f3/Neo_Geo_logo.svg/440px-Neo_Geo_logo.svg.png" )
        , ( "Astrocade", "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Bally-Arcade-Console.jpg/600px-Bally-Arcade-Console.jpg" )
        , ( "Gameboy", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Game-Boy-FL.jpg/500px-Game-Boy-FL.jpg" )
        , ( "Odyssey2", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Magnavox-Odyssey-2-Console-Set.jpg/600px-Magnavox-Odyssey-2-Console-Set.jpg" )
        , ( "Atari2600", "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Atari-2600-Wood-4Sw-Set.jpg/600px-Atari-2600-Wood-4Sw-Set.jpg" )
        , ( "SMS", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Sega-Master-System-Set.jpg/500px-Sega-Master-System-Set.jpg" )
        , ( "MegaCD", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Sega-CD-Model1-Set.jpg/500px-Sega-CD-Model1-Set.jpg" )
        , ( "SNES", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/SNES-Mod1-Console-Set.jpg/500px-SNES-Mod1-Console-Set.jpg" )
        , ( "Atari5200", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Atari-5200-4-Port-wController-L.jpg/600px-Atari-5200-4-Port-wController-L.jpg" )
        , ( "TurboGrafx16", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/TurboGrafx16-Console-Set.jpg/480px-TurboGrafx16-Console-Set.jpg" )
        , ( "ColecoVision", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/ColecoVision-wController-L.jpg/600px-ColecoVision-wController-L.jpg" )
        , ( "Vectrex", "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Vectrex-Console-Set.jpg/600px-Vectrex-Console-Set.jpg" )

        --
        -- Computers
        --
        , ( "Altair8800", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Altair_8800_Computer.jpg/600px-Altair_8800_Computer.jpg" )
        , ( "C64", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Commodore-64-Computer-FL.jpg/600px-Commodore-64-Computer-FL.jpg" )
        , ( "SharpMZ", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Sharp_MZ-700.jpg/440px-Sharp_MZ-700.jpg" )
        , ( "Amstrad", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Amstrad_CPC464.jpg/580px-Amstrad_CPC464.jpg" )
        , ( "Jupiter", "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Jupiter_ACE_%28restored%29.JPG/500px-Jupiter_ACE_%28restored%29.JPG" )
        , ( "Apogee", "https://upload.wikimedia.org/wikipedia/ru/thumb/c/c2/Apogei-bk01.jpg/274px-Apogei-bk01.jpg" )
        , ( "Minimig", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Amiga500_system.jpg/600px-Amiga500_system.jpg" )
        , ( "QL", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Sinclair_QL_Top.jpg/600px-Sinclair_QL_Top.jpg" )
        , ( "ht1080z", "https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Radioshack_TRS80-IMG_7206.jpg/560px-Radioshack_TRS80-IMG_7206.jpg" )
        , ( "MSX", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Sony_HitBit_HB-10P_%28White_Background%29.jpg/440px-Sony_HitBit_HB-10P_%28White_Background%29.jpg" )
        , ( "MacPlus", "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Macintosh822014.JPG/600px-Macintosh822014.JPG" )
        , ( "Ti994a", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/TI99-IMG_7132_%28filter_levels_crop%29.jpg/600px-TI99-IMG_7132_%28filter_levels_crop%29.jpg" )
        , ( "Apple-II", "https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Apple_II_typical_configuration_1977.png/600px-Apple_II_typical_configuration_1977.png" )
        , ( "VIC20", "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Commodore-VIC-20-FL.jpg/600px-Commodore-VIC-20-FL.jpg" )
        , ( "Apple-I", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Apple_1_Woz_1976_at_CHM.agr_cropped.jpg/600px-Apple_1_Woz_1976_at_CHM.agr_cropped.jpg" )
        , ( "Vector-06C", "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Vector-06c.JPG/640px-Vector-06c.JPG" )
        , ( "Archie", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/AcornArchimedes-Wiki.jpg/600px-AcornArchimedes-Wiki.jpg" )
        , ( "Aquarius", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Mattel-Aquarius-Computer-FL.jpg/600px-Mattel-Aquarius-Computer-FL.jpg" )
        , ( "ORAO", "https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Orao-IMG_7278.jpg/600px-Orao-IMG_7278.jpg" )
        , ( "X68000", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/X68000ACE-HD.JPG/400px-X68000ACE-HD.JPG" )
        , ( "Oric", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Oric1.jpg/400px-Oric1.jpg" )
        , ( "ZX-Spectrum", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/ZXSpectrum48k.jpg/600px-ZXSpectrum48k.jpg" )
        , ( "BK0011M", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Bk0010-01-sideview.jpg/640px-Bk0010-01-sideview.jpg" )
        , ( "Atari800", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Atari-800-Computer-FL.jpg/600px-Atari-800-Computer-FL.jpg" )
        , ( "PDP1", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Steve_Russell_and_PDP-1.png/440px-Steve_Russell_and_PDP-1.png" )
        , ( "ZX81", "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Sinclair-ZX81.png/600px-Sinclair-ZX81.png" )
        , ( "BBCMicro", "https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/BBC_Micro_Front_Restored.jpg/600px-BBC_Micro_Front_Restored.jpg" )
        , ( "PET2001", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Commodore_2001_Series-IMG_0448b.jpg/560px-Commodore_2001_Series-IMG_0448b.jpg" )
        , ( "ao486", "https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Intel_i486_DX_25MHz_SX328.jpg/1024px-Intel_i486_DX_25MHz_SX328.jpg" )
        , ( "C16", "https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Commodore_16_002a.png/600px-Commodore_16_002a.png" )
        , ( "SAMCoupe", "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/SAM_Coup%C3%A9.jpg/600px-SAM_Coup%C3%A9.jpg" )
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


romDecoder : Decode.Decoder Rom
romDecoder =
    Decode.map Rom <| Decode.field "zip" Decode.string


rbfDecoder : Decode.Decoder RBF
rbfDecoder =
    Decode.map4 RBF
        (Decode.field "filename" Decode.string)
        (Decode.field "codename" Decode.string)
        (Decode.field "lpath" <| Decode.list Decode.string)
        (Decode.field "path" Decode.string)


mraDecoder : Decode.Decoder MRA
mraDecoder =
    Decode.map7 MRA
        (Decode.field "path" Decode.string)
        (Decode.field "filename" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "lpath" <| Decode.list Decode.string)
        (Decode.field "md5" Decode.string)
        (Decode.field "roms" <| Decode.map (Maybe.withDefault []) <| Decode.nullable <| Decode.list romDecoder)
        (Decode.field "roms_found" Decode.bool)


coreDecoder : Decode.Decoder (List Core)
coreDecoder =
    Decode.map2 (++)
        (Decode.field "rbfs" <| Decode.list <| Decode.map RBFCore rbfDecoder)
        (Decode.field "mras" <| Decode.list <| Decode.map MRACore mraDecoder)


platformDecoder : Decode.Decoder Platform
platformDecoder =
    Decode.map2 Platform
        (Decode.field "name" Decode.string)
        (Decode.field "codename" (Decode.list Decode.string))


toGame : String -> String -> String -> String -> String -> Game
toGame path filename name system md5 =
    if name == "" || system == "" || md5 == "" then
        UnrecognizedGame { path = path, filename = filename }

    else
        RecognizedGame { path = path, filename = filename, name = name, system = system, md5 = md5 }


gameDecoder : String -> Decode.Decoder Game
gameDecoder prefix =
    Decode.map5 toGame
        (Decode.map2 (++)
            (Decode.succeed prefix)
            (Decode.index 0 Decode.string)
        )
        (Decode.index 1 Decode.string)
        (Decode.index 2 Decode.string)
        (Decode.index 3 Decode.string)
        (Decode.index 4 Decode.string)


type alias Flags =
    {}


type CoreState
    = CoresNotFound
    | ScanningCores
    | CoresLoaded (List Core)


type Contents
    = Contents (Dict String GameTree)


type ScanStatus
    = ScanFound
    | ScanMissing
    | ScanRequested
    | ScanDeleteRequested


type alias GameTree =
    { path : String
    , scanned : ScanStatus
    , contents : Contents
    }


type ZipperParent
    = ZipperParent GameTreeZipper


type alias GameTreeZipper =
    { name : String
    , parent : Maybe ZipperParent
    , current : GameTree
    }


type alias GameFolder =
    { label : String
    , path : String
    }


type Game
    = RecognizedGame
        { path : String
        , filename : String
        , name : String
        , system : String
        , md5 : String
        }
    | UnrecognizedGame
        { path : String
        , filename : String
        }


type alias GameInfo =
    { tree : TV.Model GameFolder String Never ()
    , loaded : Dict String Bool
    , list : Dict String (List Game)
    , topFolder : GameTree
    , folder : Maybe GameFolder
    , filter : Maybe String
    , scanningOn : Maybe String
    , page : Int
    , missingThumbnails : Set.Set String
    }


type GameState
    = GameFoldersNotFound
    | ScanningGameFolders
    | GameFoldersLoaded GameInfo


type alias Model =
    { navKey : Navigation.Key
    , page : Page
    , coreFilter : Maybe String
    , navState : Navbar.State
    , modalVisibility : Modal.Visibility
    , modalTitle : String
    , modalBody : List (Html Msg)
    , modalFooter : List (Html Msg)
    , messages : List Panel
    , cores : CoreState
    , games : GameState
    , folderSettingsNav : Maybe GameTreeZipper
    , openContentWithDialog : ContentLoadInfo
    , gameLoaderScript : Maybe String
    , platforms : Maybe (List Platform)
    , waiting : Int
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
    | GamesPage
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


type alias CoreFolder =
    { label : String
    , content : List Core
    , path : List String
    }


type alias ContentLoadInfo =
    { script : String
    , method : String
    , coreCodeName : String
    , corePath : String
    , rom : String
    , isZip : Bool
    }


emptyContentLoadInfo =
    { script = ""
    , method = ""
    , coreCodeName = ""
    , corePath = ""
    , rom = ""
    , isZip = False
    }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate url
                { navKey = key
                , coreFilter = Nothing
                , navState = navState
                , page = AboutPage
                , modalVisibility = Modal.hidden
                , modalTitle = ""
                , modalBody = []
                , modalFooter = [ Button.button [ Button.warning, Button.onClick CloseModal ] [ text "Proceed" ] ]
                , cores = CoresNotFound
                , games = GameFoldersNotFound
                , folderSettingsNav = Nothing
                , openContentWithDialog = emptyContentLoadInfo
                , gameLoaderScript = Nothing
                , platforms = Nothing
                , waiting = 3 -- Per loadCores ...
                , messages = []
                , currentVersion = ""
                , latestRelease = ""
                , updateStatus = NotReady
                , missingThumbnails = []
                , currentPath = []
                , treeViewModel = TV.initializeModel coreTreeCfg []
                , selectedCoreFolder = Nothing
                , activePageIdx = 0
                , selectedCore = Nothing
                }
    in
    ( model
    , Cmd.batch
        [ urlCmd
        , navCmd
        , loadCores
        , loadGameFolders
        , loadGameLoaderScript
        , checkCurrentVersion
        ]
    )


type Msg
    = UrlChange Url
    | ClickedLink UrlRequest
    | NavMsg Navbar.State
    | CloseModal
    | ShowModal String (List (Html Msg)) (List (Html Msg))
    | LoadCore String
    | GameLoaded (Result Http.Error ())
    | CoreSyncFinished (Result Http.Error ())
    | GameFolderScanFinished (Result Http.Error ())
    | GameScanFinished (Result Http.Error ())
    | LoadCores
    | LoadContent ContentLoadInfo
    | ConfigureCustomContentLoad ContentLoadInfo
    | ScanCores Bool
    | ScanGameFolders
    | ScanGames String
    | DeleteGameScan String
    | GotCores (Result Http.Error (List Core))
    | GotGameFolders (Result Http.Error GameTree)
    | GotGameLoaderScript (Result Http.Error String)
    | FilterCores String
    | GotGameScan String (Result Http.Error (List Game))
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
    | CoreTreeViewMsg (TV.Msg String)
    | CorePaginationMsg Int
    | SelectCore (Maybe Core)
    | GameTreeViewMsg (TV.Msg String)
    | FilterGames String
    | GamePaginationMsg Int
    | GameMissingThumbnail String
    | SettingFolderNav FolderNavMsg


type FolderNavMsg
    = NavUp GameTreeZipper
    | NavDown ( String, GameTree )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navbar.subscriptions model.navState NavMsg
        , Sub.map CoreTreeViewMsg <| TV.subscriptions model.treeViewModel
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
            ( { model
                | modalVisibility = Modal.shown
                , modalTitle = title
                , modalBody = body
                , modalFooter = action
              }
            , Cmd.none
            )

        LoadCore path ->
            ( { model | modalVisibility = Modal.hidden }, loadCore path )

        GameLoaded _ ->
            ( model, Cmd.none )

        LoadCores ->
            ( { model | waiting = model.waiting + 1 }, loadCores )

        GotCores c ->
            case c of
                Ok cs ->
                    let
                        ( treeModel, _ ) =
                            TV.expandOnly firstLevel <| TV.initializeModel coreTreeCfg (buildNodes cs)
                    in
                    ( { model
                        | waiting = model.waiting - 1
                        , treeViewModel = treeModel
                        , cores = CoresLoaded cs
                      }
                    , Cmd.none
                    )

                Err (Http.BadStatus 404) ->
                    ( { model
                        | waiting = model.waiting - 1
                        , cores = CoresNotFound
                      }
                    , Cmd.none
                    )

                Err e ->
                    ( { model
                        | waiting = model.waiting - 1
                        , messages = newPanel Error "Error parsing cores" (errorToString e) :: model.messages
                      }
                    , Cmd.none
                    )

        ScanCores force ->
            ( { model
                | cores = ScanningCores
                , waiting = model.waiting + 1
              }
            , syncCores force
            )

        CoreSyncFinished c ->
            case c of
                Ok cs ->
                    ( model, loadCores )

                Err e ->
                    ( { model
                        | cores = CoresNotFound
                        , waiting = model.waiting - 1
                        , messages = newPanel Error "Error scanning cores" (errorToString e) :: model.messages
                      }
                    , Cmd.none
                    )

        ClosePanel id vis ->
            ( { model | messages = List.indexedMap (changePanelVisibility vis id) model.messages }, Cmd.none )

        FilterCores s ->
            if s == "" then
                let
                    ( treeModel, _ ) =
                        TV.expandOnly firstLevel (TV.collapseAll model.treeViewModel)
                in
                ( { model
                    | coreFilter = Nothing
                    , treeViewModel = treeModel
                    , activePageIdx = 0
                  }
                , Cmd.none
                )

            else
                let
                    ( treeModel, highlit ) =
                        TV.expandOnly (matchCoreFolder s) model.treeViewModel
                in
                ( { model
                    | coreFilter = Just s
                    , activePageIdx = 0
                    , treeViewModel = treeModel
                  }
                , Cmd.none
                )

        GotCurrentVersion x ->
            case x of
                Ok v ->
                    ( { model
                        | waiting = model.waiting - 1
                        , currentVersion = v
                      }
                    , Cmd.none
                    )

                Err e ->
                    ( { model
                        | waiting = model.waiting - 1
                        , messages = newPanel Error "Error retrieving current version" (errorToString e) :: model.messages
                      }
                    , Cmd.none
                    )

        CheckLatestRelease ->
            ( { model
                | updateStatus = CheckingLatest
                , waiting = model.waiting + 1
              }
            , checkLatestRelease
            )

        GotLatestRelease x ->
            case x of
                Ok v ->
                    let
                        latest =
                            List.foldr firstJust Nothing v
                    in
                    case latest of
                        Nothing ->
                            ( { model
                                | waiting = model.waiting - 1
                                , updateStatus = OnLatestRelease
                              }
                            , Cmd.none
                            )

                        Just l ->
                            ( { model
                                | waiting = model.waiting - 1
                                , latestRelease = l
                                , updateStatus =
                                    if l == model.currentVersion then
                                        OnLatestRelease

                                    else
                                        UpdateAvailable
                              }
                            , Cmd.none
                            )

                Err e ->
                    ( { model
                        | waiting = model.waiting - 1
                        , messages = newPanel Error "Error checking latest release" (errorToString e) :: model.messages
                        , updateStatus = ReadyToCheck
                      }
                    , Cmd.none
                    )

        Update v ->
            ( { model
                | updateStatus = Updating
                , waiting = model.waiting + 1
              }
            , updateToRelease v
            )

        GotUpdateResult x ->
            case x of
                Ok _ ->
                    ( model, rebootBackend )

                Err e ->
                    ( { model
                        | waiting = model.waiting - 1
                        , updateStatus = UpdateAvailable
                        , messages = newPanel Error "Error updating WebMenu :(" (errorToString e) :: model.messages
                      }
                    , Cmd.none
                    )

        Reload ->
            ( model, reload () )

        GotReboot x ->
            case x of
                Ok _ ->
                    ( model, checkNewVersion )

                Err _ ->
                    ( model, rebootBackend )

        GotNewVersion x ->
            case x of
                Ok v ->
                    if v /= model.currentVersion then
                        ( { model
                            | waiting = model.waiting - 1
                            , updateStatus = WaitingForReboot
                            , modalVisibility = Modal.shown
                            , modalTitle = "Updated Successfully!"
                            , modalBody = [ text "Click to finish the installation." ]
                            , modalFooter = [ Button.button [ Button.warning, Button.onClick Reload ] [ text "Proceed" ] ]
                          }
                        , Cmd.none
                        )

                    else
                        ( model, checkNewVersion )

                Err _ ->
                    ( model, checkNewVersion )

        MissingThumbnail x ->
            ( { model | missingThumbnails = x :: model.missingThumbnails }
            , Cmd.none
            )

        CoreTreeViewMsg tvm ->
            let
                treeView =
                    TV.update tvm model.treeViewModel
            in
            ( { model
                | treeViewModel = treeView
                , activePageIdx = 0
                , selectedCoreFolder = TV.getSelected treeView |> Maybe.map .node |> Maybe.map T.dataOf
              }
            , Cmd.none
            )

        CorePaginationMsg i ->
            ( { model
                | activePageIdx = i
              }
            , Cmd.none
            )

        SelectCore mc ->
            ( { model | selectedCore = mc }
            , Cmd.none
            )

        ScanGameFolders ->
            ( { model
                | games = ScanningGameFolders
                , waiting = model.waiting + 1
              }
            , syncGameFolder
            )

        GotGameScan path res ->
            case res of
                Ok games ->
                    case model.games of
                        GameFoldersLoaded current ->
                            let
                                loaded =
                                    Dict.insert path True current.loaded

                                new =
                                    DE.groupBy gamePath games

                                list =
                                    Dict.merge
                                        (\key a -> Dict.insert key a)
                                        (\key a b -> Dict.insert key (a ++ b))
                                        (\key b -> Dict.insert key b)
                                        new
                                        current.list
                                        Dict.empty
                            in
                            ( { model | games = GameFoldersLoaded { current | loaded = loaded, list = list } }
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                Err err ->
                    ( model, Cmd.none )

        GameFolderScanFinished res ->
            case res of
                Ok _ ->
                    ( model, loadGameFolders )

                Err value ->
                    ( model, Cmd.none )

        GotGameFolders res ->
            case res of
                Ok value ->
                    let
                        ( tree, _ ) =
                            TV.expandOnly underMedia <|
                                TV.initializeModel gameTreeCfg <|
                                    buildGameNodes "/" value

                        loaded =
                            Dict.fromList <| initLoadedGameFolders value

                        list =
                            Dict.empty
                    in
                    ( { model
                        | games =
                            GameFoldersLoaded
                                { tree = tree
                                , loaded = loaded
                                , list = list
                                , topFolder = value
                                , folder = Nothing
                                , filter = Nothing
                                , scanningOn = Nothing
                                , page = 0
                                , missingThumbnails = Set.empty
                                }
                        , folderSettingsNav =
                            Just
                                { parent = Nothing
                                , name = "/"
                                , current = value
                                }
                        , waiting = model.waiting - 1
                      }
                    , Cmd.batch
                        (List.map loadGameScan (Dict.keys loaded))
                    )

                Err value ->
                    ( { model | waiting = model.waiting - 1 }
                    , Cmd.none
                    )

        GameTreeViewMsg tvm ->
            case model.games of
                GameFoldersLoaded games ->
                    let
                        tree =
                            TV.update tvm games.tree

                        folder =
                            TV.getSelected tree |> Maybe.map .node |> Maybe.map T.dataOf
                    in
                    ( { model
                        | games =
                            GameFoldersLoaded
                                { games
                                    | tree = tree
                                    , folder = folder
                                    , page = 0
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        FilterGames s ->
            case model.games of
                GameFoldersLoaded games ->
                    let
                        filter =
                            if s == "" then
                                Nothing

                            else
                                Just s
                    in
                    ( { model
                        | games =
                            GameFoldersLoaded
                                { games
                                    | filter = filter
                                    , page = 0
                                }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        GameMissingThumbnail s ->
            case model.games of
                GameFoldersLoaded games ->
                    ( { model
                        | games = GameFoldersLoaded { games | missingThumbnails = Set.insert s games.missingThumbnails }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        GamePaginationMsg i ->
            case model.games of
                GameFoldersLoaded games ->
                    ( { model
                        | games = GameFoldersLoaded { games | page = i }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ScanGames path ->
            case model.games of
                GameFoldersLoaded games ->
                    ( { model
                        | waiting = model.waiting + 1
                        , games = GameFoldersLoaded { games | scanningOn = Just path }
                      }
                    , scanForGamesInFolder path
                    )

                _ ->
                    ( model, Cmd.none )

        GameScanFinished res ->
            case res of
                Ok _ ->
                    ( model, loadGameFolders )

                Err e ->
                    ( { model
                        | messages = newPanel Error "Error scanning games" (errorToString e) :: model.messages
                      }
                    , loadGameFolders
                    )

        DeleteGameScan path ->
            case model.games of
                GameFoldersLoaded games ->
                    ( { model
                        | games = GameFoldersLoaded { games | scanningOn = Just "" }
                        , waiting = model.waiting + 1
                      }
                    , deleteGameScan path
                    )

                _ ->
                    ( model, Cmd.none )

        GotGameLoaderScript res ->
            case res of
                Ok script ->
                    ( { model | gameLoaderScript = Just script }
                    , Cmd.none
                    )

                Err e ->
                    ( { model
                        | messages = newPanel Error "Couldn't get loader script" ("Content launching will be disabled.\n" ++ errorToString e) :: model.messages
                      }
                    , loadGameFolders
                    )

        LoadContent info ->
            case model.gameLoaderScript of
                Just script ->
                    ( { model
                        | modalVisibility = Modal.hidden
                      }
                    , loadContent { info | script = script }
                    )

                Nothing ->
                    ( model, Cmd.none )

        ConfigureCustomContentLoad info ->
            case ( model.cores, model.gameLoaderScript ) of
                ( CoresLoaded cs, Just script ) ->
                    let
                        info2 =
                            { info | script = script }
                    in
                    ( { model
                        | openContentWithDialog = info
                        , modalVisibility = Modal.shown
                        , modalTitle = "Open content with..."
                        , modalBody = openContentWithForm cs info
                        , modalFooter =
                            [ Button.button
                                [ Button.primary
                                , Button.onClick <| LoadContent info
                                ]
                                [ text "Load" ]
                            ]
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        SettingFolderNav m ->
            case m of
                NavUp zipper ->
                    ( { model | folderSettingsNav = Just zipper }
                    , Cmd.none
                    )

                NavDown ( name, tree ) ->
                    case model.folderSettingsNav of
                        Nothing ->
                            ( model, Cmd.none )

                        Just parent ->
                            ( { model
                                | folderSettingsNav =
                                    Just
                                        { parent = Just <| ZipperParent parent
                                        , name = name
                                        , current = tree
                                        }
                              }
                            , Cmd.none
                            )


coreSelect : String -> Core -> Maybe (Select.Item Msg)
coreSelect selectedPath c =
    case c of
        MRACore _ ->
            Nothing

        RBFCore r ->
            Just <|
                Select.item
                    [ value (r.path ++ ";" ++ r.codename)
                    , selected (r.path == selectedPath)
                    ]
                    [ text r.filename ]


openContentWithForm : List Core -> ContentLoadInfo -> List (Html Msg)
openContentWithForm cs info =
    [ Form.form []
        [ h4 [] [ text "Content" ]
        , Form.group []
            [ Form.label [] [ text "Path" ]
            , Input.text
                [ Input.attrs
                    [ value info.rom
                    , onInput (\s -> ConfigureCustomContentLoad { info | rom = s })
                    ]
                ]
            ]
        , Form.label [] [ text "Format" ]
        , Fieldset.config
            |> Fieldset.children
                [ Checkbox.custom
                    [ Checkbox.id "isZip"
                    , Checkbox.inline
                    , Checkbox.checked info.isZip
                    , Checkbox.onCheck (\s -> ConfigureCustomContentLoad { info | isZip = s })
                    ]
                    "Zip file"
                ]
            |> Fieldset.view
        , p [] []
        , h4 [] [ text "Core" ]
        , Form.group []
            [ Form.label [] [ text "Path" ]
            , Select.select
                [ Select.onChange
                    (\s ->
                        let
                            parts =
                                String.split ";" s

                            corePath =
                                parts |> getAt 0 |> Maybe.withDefault ""

                            coreCodeName =
                                parts |> getAt 1 |> Maybe.withDefault ""
                        in
                        ConfigureCustomContentLoad
                            { info
                                | corePath = corePath
                                , coreCodeName = coreCodeName
                            }
                    )
                ]
                (List.filterMap (coreSelect info.corePath) cs)
            ]
        ]
    ]


initLoadedGameFolders : GameTree -> List ( String, Bool )
initLoadedGameFolders tree =
    let
        head =
            if tree.scanned == ScanFound then
                [ ( tree.path, False ) ]

            else
                []
    in
    case tree.contents of
        Contents rest ->
            head
                ++ (Dict.values rest
                        |> List.map initLoadedGameFolders
                        |> List.concat
                   )


underMedia : GameFolder -> Bool
underMedia gf =
    gf.path == "/media/fat"


firstLevel : CoreFolder -> Bool
firstLevel cf =
    List.length cf.path == 1


matchCoreFolder : String -> CoreFolder -> Bool
matchCoreFolder st cf =
    String.contains st cf.label || List.any (cName >> String.toLower >> String.contains st) cf.content


firstJust : Maybe a -> Maybe a -> Maybe a
firstJust l r =
    case l of
        Nothing ->
            r

        Just x ->
            Just x


newPanel : PanelType -> String -> String -> Panel
newPanel ptype title text =
    { title = title
    , text = text
    , style = ptype
    , visibility = Alert.shown
    }


changePanelVisibility : Alert.Visibility -> Int -> Int -> Panel -> Panel
changePanelVisibility vis id current panel =
    if current == id then
        { panel | visibility = vis }

    else
        panel


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
            , url = relative [ "api", "webmenu", "reboot" ] []
            , body = Http.emptyBody
            , timeout = Nothing
            , resolver = Http.stringResolver <| ignoreResolver
            }
        )


ignoreResolver : Http.Response String -> Result Http.Error ()
ignoreResolver response =
    case response of
        Http.GoodStatus_ _ body ->
            Ok ()

        x ->
            Err Http.Timeout


checkCurrentVersion : Cmd Msg
checkCurrentVersion =
    Http.get
        { url = relative [ "api", "version", "current" ] []
        , expect = Http.expectString GotCurrentVersion
        }


checkNewVersion : Cmd Msg
checkNewVersion =
    Task.attempt GotNewVersion
        (Process.sleep 3000
            |> Task.andThen
                (\_ ->
                    Http.task
                        { method = "GET"
                        , headers = []
                        , url = relative [ "api", "version", "current" ] []
                        , body = Http.emptyBody
                        , timeout = Nothing
                        , resolver = Http.stringResolver <| passStringResolver
                        }
                )
        )


passStringResolver : Http.Response String -> Result Http.Error String
passStringResolver response =
    case response of
        Http.GoodStatus_ _ body ->
            Ok body

        x ->
            Err Http.Timeout


decodeReleases : Decode.Decoder (List (Maybe String))
decodeReleases =
    Decode.list
        (Decode.map3
            decodeStable
            (Decode.field "tag_name" Decode.string)
            (Decode.field "draft" Decode.bool)
            (Decode.field "prerelease" Decode.bool)
        )


checkLatestRelease : Cmd Msg
checkLatestRelease =
    Http.get
        { url = githubAPI [ "releases" ]
        , expect = Http.expectJson GotLatestRelease decodeReleases
        }


updateToRelease : String -> Cmd Msg
updateToRelease v =
    Http.post
        { url = relative [ "api", "update" ] [ string "version" v ]
        , body = Http.emptyBody
        , expect = Http.expectWhatever GotUpdateResult
        }


decodeStable : String -> Bool -> Bool -> Maybe String
decodeStable tag draft prerelease =
    if draft || prerelease then
        Nothing

    else
        Just tag


syncCores : Bool -> Cmd Msg
syncCores force =
    Http.get
        { url =
            relative [ "api", "cores", "scan" ]
                [ int "force"
                    (if force then
                        1

                     else
                        0
                    )
                ]
        , expect = Http.expectWhatever CoreSyncFinished
        }


boolToScanStatus : Bool -> ScanStatus
boolToScanStatus x =
    case x of
        True ->
            ScanFound

        False ->
            ScanMissing


scanStatusDecoder : Decode.Decoder ScanStatus
scanStatusDecoder =
    Decode.map boolToScanStatus Decode.bool


gameTreeDecoder : Decode.Decoder GameTree
gameTreeDecoder =
    Decode.map3 GameTree
        (Decode.field "path" Decode.string)
        (Decode.field "scanned" scanStatusDecoder)
        (Decode.field "contents" <| Decode.map Contents <| Decode.dict <| Decode.lazy <| \_ -> gameTreeDecoder)


syncGameFolder : Cmd Msg
syncGameFolder =
    Http.get
        { url =
            relative [ "api", "folder", "scan" ] [ string "path" "/media" ]
        , expect = Http.expectWhatever GameFolderScanFinished
        }


scanForGamesInFolder : String -> Cmd Msg
scanForGamesInFolder path =
    Http.get
        { url =
            relative [ "api", "games", "scan" ] [ string "path" path ]
        , expect = Http.expectWhatever GameScanFinished
        }


deleteGameScan : String -> Cmd Msg
deleteGameScan path =
    Http.request
        { method = "DELETE"
        , headers = []
        , url =
            relative [ "api", "games", "scan" ] [ string "path" path ]
        , body = Http.emptyBody
        , expect = Http.expectWhatever GameScanFinished
        , timeout = Nothing
        , tracker = Nothing
        }


loadCores : Cmd Msg
loadCores =
    Http.get
        { url = relative [ "cached", "cores.json" ] []
        , expect = Http.expectJson GotCores coreDecoder
        }


loadGameLoaderScript : Cmd Msg
loadGameLoaderScript =
    Http.get
        { url = relative [ "assets", "scripts", "load.lua" ] []
        , expect = Http.expectString GotGameLoaderScript
        }


loadGameFolders : Cmd Msg
loadGameFolders =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Cache-Control" "no-store" ]
        , url = relative [ "cached", "folders.json" ] []
        , body = Http.emptyBody
        , expect = Http.expectJson GotGameFolders gameTreeDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


decodeJsonLines : Decoder a -> String -> Result Decode.Error (List a)
decodeJsonLines decoder lines =
    String.lines lines
        |> List.map (Decode.decodeString decoder)
        |> Result.Extra.combine


expectJsonLines : (Result Http.Error (List a) -> msg) -> Decoder a -> Http.Expect msg
expectJsonLines toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata body ->
                    case decodeJsonLines decoder (String.trim body) of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (Decode.errorToString err))


loadGameScan : String -> Cmd Msg
loadGameScan scan =
    Http.get
        { url = relative [ "cached", "games", scan ++ ".jsonl" ] []
        , expect = expectJsonLines (GotGameScan scan) (gameDecoder scan)
        }


loadCore : String -> Cmd Msg
loadCore lpath =
    Http.get
        { url = relative [ "api", "run" ] [ string "path" lpath ]
        , expect = Http.expectWhatever GameLoaded
        }


loadContent : ContentLoadInfo -> Cmd Msg
loadContent info =
    Http.post
        { url = relative [ "api", "script", "run" ] []
        , body = Http.jsonBody (loadScriptEncoder info)
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
    { url
        | path = url.fragment |> Maybe.withDefault ""
        , fragment = Nothing
    }
        |> UrlParser.parse routeParser


routeParser : Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map AboutPage top
        , UrlParser.map CoresPage <| UrlParser.s "cores"
        , UrlParser.map GamesPage <| UrlParser.s "content"
        , UrlParser.map (NotImplementedPage "Community" "View MiSTer news, and receive community updates and relevant content") <| UrlParser.s "community"
        , UrlParser.map SettingsPage <| UrlParser.s "settings"
        , UrlParser.map AboutPage <| UrlParser.s "about"
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
    div [ class "mb-1" ]
        [ Grid.row []
            [ Grid.col [] (List.indexedMap showPanel model.messages) ]
        ]


showPanel : Int -> Panel -> Html Msg
showPanel id panel =
    Alert.config
        |> Alert.dismissableWithAnimation (ClosePanel id)
        |> (case panel.style of
                Info ->
                    Alert.info

                Error ->
                    Alert.danger
           )
        |> Alert.children
            [ Alert.h4 [] [ text panel.title ]
            , p [] [ text panel.text ]
            ]
        |> Alert.view panel.visibility


menu : Model -> Html Msg
menu model =
    div [ class "mb-2" ]
        [ Navbar.config NavMsg
            |> Navbar.withAnimation
            |> Navbar.dark
            |> Navbar.collapseSmall
            |> Navbar.container
            |> Navbar.brand [ class "text-white" ] [ strong [] [ text "MiSTer" ] ]
            |> Navbar.items
                [ Navbar.itemLink [ href "#cores" ] [ text "Cores" ]
                , Navbar.itemLink [ href "#content" ] [ text "Content" ]
                , Navbar.itemLink [ href "#community" ] [ text "Community" ]
                , Navbar.itemLink [ href "#settings" ] [ text "Settings" ]
                , Navbar.itemLink [ href "#about" ] [ text "About" ]
                ]
            |> Navbar.customItems
                [ Navbar.customItem
                    (if model.waiting > 0 then
                        Spinner.spinner
                            [ Spinner.grow
                            , Spinner.color Text.light
                            ]
                            []

                     else
                        text ""
                    )
                ]
            |> Navbar.view model.navState
        ]


mainContent : Model -> Html Msg
mainContent model =
    Grid.container []
        ([ messages model ]
            ++ (case model.page of
                    AboutPage ->
                        pageAboutPage model

                    CoresPage ->
                        pageCoresPage model

                    GamesPage ->
                        pageGamesPage model

                    SettingsPage ->
                        pageSettingsPage model

                    NotImplementedPage title description ->
                        pageNotImplemented title description

                    NotFound ->
                        pageNotFound
               )
        )


sectionHeading : String -> String -> Html Msg
sectionHeading title motto =
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ h1 [ class "display-4" ] [ text title ]
                , p [ class "lead" ] [ text motto ]
                ]
            ]
        ]


pageSettingsPage : Model -> List (Html Msg)
pageSettingsPage model =
    [ sectionHeading "Settings" "WebMenu and MiSTer configuration"
    , scanCoresBlock model
    , scanGamesBlock model
    , checkForUpdatesBlock model
    ]


scanGamesBlock model =
    Card.config
        [ Card.outlineDark
        , Card.attrs [ Spacing.mb3 ]
        ]
        |> Card.headerH3 [] [ text "Content" ]
        |> Card.block []
            [ Block.text []
                ([ p [] [ text "Click on 'Scan now' to start scanning for available game folders in your MiSTer." ]
                 ]
                    ++ (case model.games of
                            GameFoldersNotFound ->
                                [ Button.button
                                    [ Button.primary
                                    , Button.onClick ScanGameFolders
                                    ]
                                    [ text "Scan folders" ]
                                ]

                            ScanningGameFolders ->
                                [ Button.button
                                    [ Button.primary
                                    , Button.disabled True
                                    ]
                                    [ text "Scan folders" ]
                                ]

                            GameFoldersLoaded games ->
                                [ Button.button
                                    [ Button.secondary
                                    , Button.onClick ScanGameFolders
                                    ]
                                    [ text "Scan folders" ]
                                ]
                       )
                )
            ]
        |> Card.block []
            (case ( model.folderSettingsNav, model.games ) of
                ( Just folders, GameFoldersLoaded games ) ->
                    [ Block.text []
                        [ Grid.container []
                            [ Grid.row []
                                [ Grid.col [ Col.sm6 ]
                                    [ h4 [] [ text "Folders" ]
                                    , ListGroup.ul <| [ ListGroup.li [ ListGroup.light ] [ text folders.current.path ] ] ++ folderSelector games.scanningOn folders
                                    ]
                                , Grid.col [ Col.sm6 ]
                                    [ h4 [] [ text "Scanned" ]
                                    , ListGroup.ul <| scannedFolderSelector games.scanningOn games.topFolder
                                    ]
                                ]
                            ]
                        ]
                    ]

                _ ->
                    []
            )
        |> Card.view


scanCoresBlock model =
    Card.config
        [ Card.outlineDark
        , Card.attrs [ Spacing.mb3 ]
        ]
        |> Card.headerH3 [] [ text "Cores" ]
        |> Card.block []
            [ Block.text []
                [ p [] [ text "Click on 'Scan now' to start scanning for available cores in your MiSTer." ]
                , p [] [ text "This may take a couple of minutes depending on the number of files in your SD card." ]
                ]
            , Block.custom <|
                Button.button
                    [ Button.disabled <| model.cores == ScanningCores
                    , Button.primary
                    , Button.onClick <| ScanCores True
                    ]
                    [ text "Scan now" ]
            ]
        |> Card.view


checkForUpdatesBlock model =
    Card.config
        [ Card.outlineDark
        , Card.attrs [ Spacing.mb3 ]
        ]
        |> Card.headerH3 [] [ text "WebMenu Update" ]
        |> Card.block []
            [ Block.text []
                [ p [] [ text "Check for new releases of WebMenu." ]
                , p []
                    [ text "You are currently running "
                    , strong [] [ text model.currentVersion ]
                    ]
                ]
            , Block.custom <|
                Button.button
                    [ Button.disabled (model.updateStatus == ReadyToCheck)
                    , Button.info
                    , Button.onClick CheckLatestRelease
                    ]
                    [ text "Check for updates" ]
            ]
        |> Card.block []
            (case model.updateStatus of
                UpdateAvailable ->
                    updateAvailableBlock model

                OnLatestRelease ->
                    onLatestReleaseBlock model

                Updating ->
                    updateAvailableBlock model

                WaitingForReboot ->
                    updateAvailableBlock model

                _ ->
                    []
            )
        |> Card.view


onLatestReleaseBlock model =
    [ Block.text [] [ strong [] [ text "You are up to date!" ] ] ]


updateAvailableBlock model =
    [ Block.titleH3 [] [ text "Update Available!" ]
    , Block.text []
        [ p []
            [ text "The latest release is "
            , strong [] [ text model.latestRelease ]
            ]
        ]
    , Block.custom <|
        Button.button
            [ Button.disabled (model.updateStatus /= UpdateAvailable)
            , Button.warning
            , Button.onClick (Update model.latestRelease)
            ]
            [ text "Update!" ]
    ]


pageAboutPage : Model -> List (Html Msg)
pageAboutPage model =
    [ Grid.row []
        [ Grid.col []
            [ h1 [ class "mt-4" ]
                [ text "Welcome to WebMenu "
                , text model.currentVersion
                , text "!\n"
                , br [] []
                , small [ class "text-muted", class "lead" ] [ text "A web interface for MiSTer" ]
                ]
            , p [] [ text "This project is an early alpha, so expect some rough edges." ]
            , p []
                [ text "Please, report any problems and/or desired feature through the project "
                , a
                    [ href "https://github.com/nilp0inter/MiSTer_WebMenu/issues"
                    , target "_blank"
                    ]
                    [ text "GitHub Issues" ]
                , text " page."
                ]
            , p [] [ text "Enjoy 😊" ]
            ]
        ]
    ]


pageNotImplemented : String -> String -> List (Html Msg)
pageNotImplemented title description =
    [ sectionHeading title description
    , Card.config []
        |> Card.block []
            [ Block.titleH3 [] [ text "Not implemented yet" ]
            , Block.text [] [ p [] [ text "This feature will be available on future versions." ] ]
            ]
        |> Card.view
    ]


pageNotFound : List (Html Msg)
pageNotFound =
    [ h1 [] [ text "Not found" ]
    , text "Sorry couldn't find that page"
    ]


modal : Model -> Html Msg
modal model =
    Modal.config CloseModal
        |> Modal.h4 [] [ text model.modalTitle ]
        |> Modal.body [] model.modalBody
        |> Modal.footer [] model.modalFooter
        |> Modal.view model.modalVisibility



-------------------------------------------------------------------------
--                                Cores                                --
-------------------------------------------------------------------------


pageCoresPage : Model -> List (Html Msg)
pageCoresPage model =
    [ sectionHeading "Cores" "Search your core collection and launch individual cores with a click"
    , pageCoresPageContent model
    ]


pageCoresPageContent : Model -> Html Msg
pageCoresPageContent model =
    case model.cores of
        CoresNotFound ->
            coreSyncButton

        ScanningCores ->
            waitForSync

        CoresLoaded cs ->
            let
                filteredBySearch =
                    case model.coreFilter of
                        Nothing ->
                            cs

                        Just s ->
                            List.filter (matchCoreByString s) cs

                filtered =
                    case model.selectedCoreFolder of
                        Nothing ->
                            filteredBySearch

                        Just cf ->
                            List.filter (filterByNode cf) filteredBySearch

                pages =
                    greedyGroupsOf 90 (List.sortBy cLpath filtered)

                selectedPage =
                    Maybe.withDefault [] (getAt model.activePageIdx pages)

                activePagination =
                    List.length pages > 1

                paginationBlock =
                    if activePagination then
                        [ simplePaginationList "#cores" pages model.activePageIdx CorePaginationMsg ]

                    else
                        []

                pageWithSections =
                    selectedPage |> DE.groupBy cLpath |> Dict.toList
            in
            Grid.container []
                [ Grid.row []
                    [ Grid.col [ Col.sm3 ]
                        [ coreSearch model
                        , Html.map CoreTreeViewMsg (TV.view model.treeViewModel)
                        ]
                    , Grid.col [ Col.sm9 ] (paginationBlock ++ (List.concat <| List.map (coreFolderContent model) pageWithSections) ++ paginationBlock)
                    ]
                ]


simplePaginationList : String -> List (List a) -> Int -> (Int -> Msg) -> Html Msg
simplePaginationList url pages active toMsg =
    Pagination.defaultConfig
        |> Pagination.ariaLabel "Pagination"
        |> Pagination.small
        |> Pagination.align HAlign.centerXs
        |> Pagination.itemsList
            { selectedMsg = toMsg
            , prevItem = Just <| Pagination.ListItem [] [ text "<<" ]
            , nextItem = Just <| Pagination.ListItem [] [ text ">>" ]
            , activeIdx = active
            , data = List.range 1 (List.length pages)
            , itemFn = \idx pcs -> Pagination.ListItem [] [ text (String.fromInt pcs) ]
            , urlFn = \idx _ -> url
            }
        |> Pagination.view


filterByNode : CoreFolder -> Core -> Bool
filterByNode cf c =
    let
        realPath =
            cf.path
                |> List.tail
                |> Maybe.map (\xs -> xs ++ [ cf.label ])
                |> Maybe.withDefault []
    in
    case stripPrefix realPath (cLpath c) of
        Nothing ->
            False

        Just _ ->
            True


gameNodeLabel : T.Node GameFolder -> String
gameNodeLabel (T.Node node) =
    node.data.label


gameNodeUid : T.Node GameFolder -> TV.NodeUid String
gameNodeUid (T.Node node) =
    TV.NodeUid node.data.path


coreNodeLabel : T.Node CoreFolder -> String
coreNodeLabel (T.Node node) =
    node.data.label


coreNodeUid : T.Node CoreFolder -> TV.NodeUid String
coreNodeUid (T.Node node) =
    node.data.path
        |> String.join "/"
        |> (++) node.data.label
        |> TV.NodeUid


singleton : List String -> String -> List Core -> T.Node CoreFolder
singleton p x cs =
    T.Node { data = { label = x, path = p, content = cs }, children = [] }


treeFromList : List String -> List String -> List Core -> Maybe (T.Node CoreFolder)
treeFromList p ss cs =
    case ss of
        [] ->
            Nothing

        [ x ] ->
            Just <|
                T.Node
                    { data = { label = x, path = p, content = cs }
                    , children = []
                    }

        x :: xs ->
            Just <|
                T.Node
                    { data = { label = x, path = p, content = [] }
                    , children =
                        treeFromList (p ++ [ x ]) xs cs
                            |> Maybe.map List.singleton
                            |> Maybe.withDefault []
                    }


gameTreeCfg : TV.Configuration GameFolder String
gameTreeCfg =
    TV.Configuration
        gameNodeUid
        -- to construct node UIDs
        gameNodeLabel
        -- to render node (data) to text
        TV.defaultCssClasses


coreTreeCfg : TV.Configuration CoreFolder String
coreTreeCfg =
    TV.Configuration
        coreNodeUid
        -- to construct node UIDs
        coreNodeLabel
        -- to render node (data) to text
        TV.defaultCssClasses


hasScannedChildren : GameTree -> Bool
hasScannedChildren folder =
    case folder.contents of
        Contents cs ->
            folder.scanned == ScanFound || List.any hasScannedChildren (Dict.values cs)


contentToNode : Bool -> ( String, GameTree ) -> T.Node GameFolder
contentToNode hasScannedParent ( label, folder ) =
    case folder.contents of
        Contents cs ->
            T.Node
                { data = { label = label, path = folder.path }
                , children =
                    if hasScannedParent || folder.scanned == ScanFound then
                        Dict.toList cs
                            |> List.map (contentToNode True)

                    else
                        Dict.toList cs
                            |> List.filter (\( l, f ) -> hasScannedChildren f)
                            |> List.map (contentToNode False)
                }


buildGameNodes : String -> GameTree -> List (T.Node GameFolder)
buildGameNodes label folder =
    case folder.contents of
        Contents cs ->
            [ T.Node
                { data = { label = label, path = folder.path }
                , children = List.map (contentToNode False) <| Dict.toList cs
                }
            ]


buildNodes : List Core -> List (T.Node CoreFolder)
buildNodes cs =
    cs
        |> DE.groupBy (\x -> [ "SD Card" ] ++ cLpath x)
        |> Dict.toList
        |> List.reverse
        |> List.filterMap (\( ss, cc ) -> treeFromList [] ss cc)
        |> List.foldl mergeForest []


getMatching : CoreFolder -> List (T.Node CoreFolder) -> List (T.Node CoreFolder) -> Maybe ( T.Node CoreFolder, List (T.Node CoreFolder) )
getMatching l prev post =
    case post of
        [] ->
            Nothing

        x :: xs2 ->
            if (T.dataOf x).label == l.label && (T.dataOf x).path == l.path then
                Just ( x, prev ++ xs2 )

            else
                getMatching l (prev ++ [ x ]) xs2


mergeForest : T.Node CoreFolder -> List (T.Node CoreFolder) -> List (T.Node CoreFolder)
mergeForest l xs =
    let
        y =
            T.dataOf l

        ys =
            T.childrenOf l
    in
    case getMatching y [] xs of
        Nothing ->
            l :: xs

        Just ( x, xs2 ) ->
            mergeAdding x l ++ xs2


mergeFolder : CoreFolder -> CoreFolder -> CoreFolder
mergeFolder f1 f2 =
    { label = f1.label
    , path = f1.path
    , content = f1.content ++ f2.content
    }


toNode : CoreFolder -> List (T.Node CoreFolder) -> T.Node CoreFolder
toNode d c =
    T.Node { data = d, children = c }


mergeAdding : T.Node CoreFolder -> T.Node CoreFolder -> List (T.Node CoreFolder)
mergeAdding l r =
    let
        x =
            T.dataOf l

        xs =
            T.childrenOf l

        y =
            T.dataOf r

        ys =
            T.childrenOf r
    in
    if x.label == y.label && x.path == y.path then
        [ toNode (mergeFolder x y) <| List.foldl mergeForest xs ys ]

    else
        [ toNode x xs, toNode y ys ]


coreSearch : Model -> Html Msg
coreSearch model =
    Keyed.node "div"
        []
        [ ( "core-search"
          , Form.form [ class "mb-4" ]
                [ InputGroup.config
                    (InputGroup.search
                        [ Input.attrs [ onInput FilterCores ]
                        , model.coreFilter
                            |> Maybe.withDefault ""
                            |> Input.value
                        ]
                    )
                    |> InputGroup.predecessors
                        [ InputGroup.span [] [ span [] [ Icon.viewIcon Icon.search ] ] ]
                    |> InputGroup.view
                ]
          )
        ]


matchCoreByString : String -> Core -> Bool
matchCoreByString t c =
    case c of
        RBFCore r ->
            String.contains
                (String.toLower t)
            <|
                String.toLower r.codename

        MRACore m ->
            String.contains (String.toLower t) (String.toLower m.name) || String.contains (String.toLower t) (String.toLower m.filename)


partition : Int -> a -> List a -> List (List a)
partition n d xs =
    if List.isEmpty xs then
        []

    else
        List.take n (xs ++ List.repeat n d) :: partition n d (List.drop n xs)


brFromPath : List String -> Html Msg
brFromPath ps =
    List.map (\x -> Breadcrumb.item [] [ text x ]) ps
        |> Breadcrumb.container


coreFolderContent : Model -> ( List String, List Core ) -> List (Html Msg)
coreFolderContent m ( path, cs ) =
    [ brFromPath path ] ++ coreContent m cs


coreKeyAndCard : Model -> Core -> ( String, Card.Config Msg )
coreKeyAndCard m c =
    ( cPath c ++ "/" ++ cFilename c, coreCard m c )


coreContent : Model -> List Core -> List (Html Msg)
coreContent m cs =
    cs
        |> List.map (coreKeyAndCard m)
        |> partition 3 ( "", emptyCard )
        |> List.map Card.keyedDeck



-- List.map Card.keyedDeck <| partition 3 ( "", emptyCard ) <| List.map (coreKeyAndCard m) cs


emptyCard =
    Card.config
        [ Card.outlineSecondary
        , Card.attrs [ class "emptycard" ]
        ]


waitForSync : Html Msg
waitForSync =
    Card.config
        [ Card.primary
        , Card.textColor Text.white
        ]
        |> Card.block []
            [ Block.titleH4 [] [ text "Please wait..." ]
            , Block.text []
                [ p [] [ text "WebMenu is scanning your MiSTer device." ]
                , p [] [ text "This may take a couple of minutes depending on the number of files in your SD card." ]
                ]
            , Block.custom <|
                Spinner.spinner [] []
            ]
        |> Card.view


coreSyncButton : Html Msg
coreSyncButton =
    Card.config []
        |> Card.block []
            [ Block.titleH4 [] [ text "No cores yet" ]
            , Block.text []
                [ p [] [ text "Click on 'Scan now' to start scanning for available cores in your MiSTer." ]
                , p [] [ text "This may take a couple of minutes depending on the number of files in your SD card." ]
                ]
            , Block.custom <|
                Button.button
                    [ Button.primary
                    , Button.onClick <| ScanCores False
                    ]
                    [ text "Scan now" ]
            ]
        |> Card.view


cardBadge : (List (Attribute msg) -> List (Html Msg) -> Html Msg) -> String -> Html Msg
cardBadge bdColor s =
    bdColor [ Spacing.ml1 ] [ text s ]


rbfCardBlock : RBF -> Block.Item Msg
rbfCardBlock m =
    Block.text [] [ cardBadge Badge.badgeDark "RBF" ]


mraCardBlock : MRA -> Block.Item Msg
mraCardBlock m =
    Block.text []
        [ cardBadge Badge.badgeDark "MRA"
        , if m.romsFound then
            cardBadge Badge.badgeSuccess "ROM Found"

          else
            cardBadge Badge.badgeWarning "ROM Missing"
        ]


ifNotMissing : Model -> String -> String
ifNotMissing m s =
    if List.member s m.missingThumbnails then
        ""

    else
        s


rbfImgTop : RBF -> String
rbfImgTop r =
    Maybe.withDefault
        ""
    <|
        get r.codename coreImages


mraImgTop : MRA -> String
mraImgTop m =
    crossOrigin
        "https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles"
        [ percentEncode m.name ++ ".png" ]
        []


coreCard : Model -> Core -> Card.Config Msg
coreCard model core =
    let
        bimap =
            coreBiMap

        title =
            cName core

        imgSrc =
            ifNotMissing model <|
                bimap mraImgTop rbfImgTop core

        body =
            bimap mraCardBlock rbfCardBlock core

        thumbnail =
            if imgSrc == "" then
                Card.block
                    [ Block.attrs
                        [ class "text-muted"
                        , class "d-flex"
                        , class "justify-content-center"
                        , class "align-items-center"
                        , class "corenoimg"
                        ]
                    ]
                    [ Block.text [] [ text <| cFilename core ] ]

            else
                Card.imgTop
                    [ src imgSrc
                    , on "error" <|
                        Decode.succeed <|
                            MissingThumbnail imgSrc
                    ]
                    []

        corePath =
            cFilename core

        game =
            ""

        path =
            cPath core

        loadEv =
            ShowModal
                "Are you sure?"
                [ p []
                    [ text "You are about to launch "
                    , strong [] [ text title ]
                    , text ". Any running game will be stopped immediately!"
                    ]
                ]
                [ Button.button
                    [ Button.warning
                    , Button.onClick <| LoadCore path
                    ]
                    [ text "Proceed" ]
                ]

        selected =
            if model.selectedCore == Just core then
                [ Block.light ]

            else
                []
    in
    Card.config
        [ Card.outlineSecondary
        , Card.attrs
            [ Spacing.mb4
            , on "mouseenter" <|
                Decode.succeed <|
                    SelectCore <|
                        Just core
            , on "mouseleave" <|
                Decode.succeed <|
                    SelectCore Nothing
            ]
        ]
        |> Card.header [ class "text-center" ] [ text title ]
        |> thumbnail
        |> Card.block
            ([ Block.attrs
                [ class "d-flex"
                , class "align-content-end"
                , class "flex-row"
                , class "flex-wrap"
                ]
             ]
                ++ selected
            )
            [ body ]
        |> Card.footer
            [ class "bg-primary"
            , class "text-center"
            , class "text-white"
            , class "runbutton"
            , on "click" (Decode.succeed loadEv)
            ]
            [ text "Run" ]



-------------------------------------------------------------------------
--                                Games                                --
-------------------------------------------------------------------------


pageGamesPage : Model -> List (Html Msg)
pageGamesPage model =
    [ sectionHeading "Content" "Search your game collection and play any ROM with a single click"
    , pageGamesPageContent model
    ]


pageGamesPageContent : Model -> Html Msg
pageGamesPageContent model =
    case model.games of
        GameFoldersNotFound ->
            noGamesPage

        ScanningGameFolders ->
            waitForSync

        GameFoldersLoaded games ->
            pageGamesLoadedContent model.cores games


gameSearch : Maybe String -> Html Msg
gameSearch f =
    Keyed.node "div"
        []
        [ ( "game-search"
          , Form.form [ class "mb-4" ]
                [ InputGroup.config
                    (InputGroup.search
                        [ Input.attrs [ onInput FilterGames ]
                        , Input.value (Maybe.withDefault "" f)
                        ]
                    )
                    |> InputGroup.predecessors
                        [ InputGroup.span [] [ span [] [ Icon.viewIcon Icon.search ] ] ]
                    |> InputGroup.view
                ]
          )
        ]


filterGame : String -> Game -> Bool
filterGame s game =
    case game of
        RecognizedGame g ->
            String.contains
                (String.toLower s)
            <|
                String.toLower g.name

        UnrecognizedGame g ->
            String.contains
                (String.toLower s)
            <|
                String.toLower g.path


filterGameByPath : String -> Game -> Bool
filterGameByPath path game =
    String.startsWith path (gamePath game)


pageGamesLoadedContent : CoreState -> GameInfo -> Html Msg
pageGamesLoadedContent cs games =
    let
        byPath =
            case games.folder of
                Nothing ->
                    games.list

                Just p ->
                    Dict.filter (\k v -> String.startsWith p.path k) games.list

        filtered =
            case games.filter of
                Nothing ->
                    byPath

                Just s ->
                    Dict.map (\k v -> List.filter (filterGame s) v) byPath

        onlyPopulated =
            Dict.filter (\k v -> not <| List.isEmpty v) filtered

        pages =
            greedyGroupsOf 90 <|
                List.take 1200 <|
                    List.concat <|
                        List.map (\( a, xs ) -> xs) <|
                            Dict.toList onlyPopulated

        selectedPage =
            Maybe.withDefault [] (getAt games.page pages)

        activePagination =
            List.length pages > 1

        paginationBlock =
            if activePagination then
                [ simplePaginationList "#content" pages games.page GamePaginationMsg ]

            else
                []

        pageWithSections =
            selectedPage
                |> DE.groupBy gamePath
                |> Dict.toList
    in
    Grid.container []
        [ Grid.row []
            [ Grid.col [ Col.sm3 ]
                [ gameSearch games.filter
                , Html.map GameTreeViewMsg (TV.view games.tree)
                ]
            , Grid.col
                [ Col.sm9 ]
              <|
                paginationBlock
                    ++ (List.concat <| List.map (gameFolderContent cs games) pageWithSections)
                    ++ paginationBlock
            ]
        ]


takeWhileLessThan : Int -> List ( a, List b ) -> List ( a, List b )
takeWhileLessThan rem xxs =
    if rem < 0 then
        []

    else
        case xxs of
            [] ->
                []

            ( h, x ) :: xs ->
                ( h, x ) :: takeWhileLessThan (rem - List.length x) xs


gameBrFromPath : String -> Html Msg
gameBrFromPath path =
    Breadcrumb.container <|
        List.map
            (\x -> Breadcrumb.item [] [ text x ])
        <|
            String.split "/" path


gameFolderContent : CoreState -> GameInfo -> ( String, List Game ) -> List (Html Msg)
gameFolderContent cs m ( path, gs ) =
    [ gameBrFromPath path ] ++ gameContent cs m gs


gameKeyAndCard : CoreState -> GameInfo -> Game -> ( String, Card.Config Msg )
gameKeyAndCard cs m g =
    ( gamePath g ++ "/" ++ gameFilename g, gameCard cs m g )


gameContent : CoreState -> GameInfo -> List Game -> List (Html Msg)
gameContent cs m gs =
    List.map Card.keyedDeck <|
        partition 3 ( "", emptyCard ) <|
            List.map (gameKeyAndCard cs m) gs


getFilename : String -> Maybe String
getFilename p =
    Just (String.split "/" p)
        |> Maybe.andThen last
        |> Maybe.andThen (\xs -> Just (String.split "." xs))
        |> Maybe.andThen List.Extra.init
        |> Maybe.andThen (\xs -> Just (String.join "." xs))


getExt : String -> Maybe String
getExt p =
    case last (String.split "." p) of
        Nothing ->
            Nothing

        Just ext ->
            Just ("." ++ ext)


gameName : Game -> String
gameName game =
    case game of
        RecognizedGame g ->
            g.name

        UnrecognizedGame g ->
            gameFilename game


gamePath : Game -> String
gamePath game =
    case game of
        RecognizedGame g ->
            g.path

        UnrecognizedGame g ->
            g.path


gameFilename : Game -> String
gameFilename game =
    case game of
        RecognizedGame g ->
            g.filename

        UnrecognizedGame g ->
            g.filename


gameMD5 : Game -> Maybe String
gameMD5 game =
    case game of
        RecognizedGame g ->
            Just g.md5

        UnrecognizedGame g ->
            Nothing


gameSystem : Game -> Maybe String
gameSystem game =
    case game of
        RecognizedGame g ->
            Just g.system

        UnrecognizedGame _ ->
            Nothing


ifNotGameMissing : GameInfo -> String -> String
ifNotGameMissing m s =
    if Set.member s m.missingThumbnails then
        ""

    else
        s


isCoreByCodeName : String -> Core -> Maybe String
isCoreByCodeName codeName =
    coreBiMap
        (always Nothing)
        (\rbf ->
            if rbf.codename == codeName then
                Just rbf.path

            else
                Nothing
        )


getCoreByCodeName : List Core -> String -> Maybe String
getCoreByCodeName cs codeName =
    List.head <| List.filterMap (isCoreByCodeName codeName) cs


isZip : String -> Bool
isZip filename =
    String.contains ".zip/" <| String.toLower filename


gameCard : CoreState -> GameInfo -> Game -> Card.Config Msg
gameCard cores model game =
    let
        titleText =
            gameName game

        imgSrc =
            ifNotGameMissing model <|
                case game of
                    RecognizedGame g ->
                        crossOrigin ("https://raw.githubusercontent.com/libretro-thumbnails/" ++ percentEncode (String.replace " " "_" g.system) ++ "/master/Named_Titles") [ percentEncode g.name ++ ".png" ] []

                    UnrecognizedGame _ ->
                        ""

        basicContentLoadInfo =
            { method = "rload"
            , coreCodeName = ""
            , corePath = ""
            , script = ""
            , rom = gamePath game ++ "/" ++ gameFilename game
            , isZip = isZip (gameFilename game)
            }

        contentLoadInfo =
            case ( cores, game ) of
                ( CoresLoaded cs, RecognizedGame g ) ->
                    case Dict.get g.system systemToCoreCodename of
                        Just coreCodeName ->
                            case getCoreByCodeName cs coreCodeName of
                                Just corePath ->
                                    Just
                                        { basicContentLoadInfo
                                            | coreCodeName = coreCodeName
                                            , corePath = corePath
                                        }

                                _ ->
                                    Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing

        loadContentOnClick =
            case contentLoadInfo of
                Nothing ->
                    []

                Just info ->
                    [ Button.onClick <|
                        ShowModal
                            "Are you sure?"
                            [ p []
                                [ text "You are about to load "
                                , strong [] [ text titleText ]
                                , text " using "
                                , strong [] [ text info.coreCodeName ]
                                , text " core. Any running game will be stopped immediately!"
                                ]
                            ]
                            [ Button.button
                                [ Button.primary
                                , Button.onClick (LoadContent info)
                                ]
                                [ text "Load" ]
                            ]
                    ]

        loadCustomContentOnClick =
            [ Button.onClick <|
                ConfigureCustomContentLoad <|
                    case contentLoadInfo of
                        Just info ->
                            info

                        Nothing ->
                            basicContentLoadInfo
            ]

        body =
            Block.text []
                (case gameSystem game of
                    Just s ->
                        List.map2 cardBadge [ Badge.badgeSecondary, Badge.badgeDark, Badge.badgeDark ] (String.split " - " s)

                    Nothing ->
                        let
                            systemBadge =
                                [ cardBadge Badge.badgeDanger "Unknown System" ]

                            extBadge =
                                [ cardBadge Badge.badgeDark (Maybe.withDefault "No Extension" (getExt <| gameFilename game)) ]
                        in
                        systemBadge ++ extBadge
                )

        thumbnail =
            if imgSrc == "" then
                Card.block
                    [ Block.attrs
                        [ class "text-muted"
                        , class "d-flex"
                        , class "justify-content-center"
                        , class "align-items-center"
                        , class "corenoimg"
                        ]
                    ]
                    [ Block.text [] [ text titleText ] ]

            else
                Card.imgTop
                    [ src imgSrc
                    , title titleText
                    , on "error" (Decode.succeed (GameMissingThumbnail imgSrc))
                    ]
                    []

        path =
            gamePath game
    in
    Card.config
        [ Card.outlineSecondary
        , Card.attrs
            [ Spacing.mb4 ]
        ]
        |> thumbnail
        |> Card.block
            [ Block.attrs
                [ class "d-flex"
                , class "align-content-end"
                , class "flex-row"
                , class "flex-wrap"
                ]
            ]
            [ body ]
        |> Card.footer
            [ class "text-right" ]
            [ ButtonGroup.buttonGroup [ ButtonGroup.small ]
                [ ButtonGroup.button
                    (List.concat
                        [ [ Button.disabled <| not <| isJust contentLoadInfo
                          , Button.primary
                          ]
                        , loadContentOnClick
                        ]
                    )
                    [ Icon.viewIcon Icon.play ]
                , ButtonGroup.button
                    (List.concat
                        [ [ Button.primary ]
                        , loadCustomContentOnClick
                        ]
                    )
                    [ Icon.viewIcon Icon.play
                    , sup [] [ Icon.viewIcon Icon.plus ]
                    ]
                ]
            ]



-- runButtonAttrs
-- [ text "Load" ]


noGamesPage : Html Msg
noGamesPage =
    Card.config []
        |> Card.block []
            [ Block.titleH4 [] [ text "No content yet" ]
            , Block.text [] [ p [] [ text "Go to Settings to configure your content." ] ]
            ]
        |> Card.view


isJust : Maybe a -> Bool
isJust x =
    case x of
        Nothing ->
            False

        Just _ ->
            True


folderSelector : Maybe String -> GameTreeZipper -> List (ListGroup.Item Msg)
folderSelector scanningOn gt =
    let
        parent =
            case gt.parent of
                Just (ZipperParent zz) ->
                    [ gameSubFolderElement scanningOn ".." ScanFound "" (onClick <| SettingFolderNav <| NavUp zz) ]

                _ ->
                    []
    in
    case gt.current.contents of
        Contents folders ->
            Dict.foldl (\k v acc -> acc ++ [ gameSubFolderElement scanningOn k v.scanned v.path (onClick <| SettingFolderNav <| NavDown ( k, v )) ]) parent folders


scannedFolderSelector : Maybe String -> GameTree -> List (ListGroup.Item Msg)
scannedFolderSelector scanningOn gt =
    (case gt.scanned of
        ScanFound ->
            [ gameFolderElement scanningOn gt.path gt.scanned ]

        _ ->
            []
    )
        ++ (case gt.scanned of
                ScanFound ->
                    []

                _ ->
                    case gt.contents of
                        Contents c ->
                            Dict.foldr (\k v acc -> scannedFolderSelector scanningOn v ++ acc) [] c
           )


scanningSpinner : String -> Maybe String -> String -> String -> List (Html Msg)
scanningSpinner path scanningOn textNoScanning textScanning =
    case scanningOn of
        Nothing ->
            [ text textNoScanning ]

        Just p ->
            if p == path then
                [ Spinner.spinner [ Spinner.small, Spinner.attrs [ Spacing.mr1 ] ] []
                , text textScanning
                ]

            else
                [ text textNoScanning ]


gameSubFolderElement : Maybe String -> String -> ScanStatus -> String -> Attribute Msg -> ListGroup.Item Msg
gameSubFolderElement scanningOn name scanned path clickEv =
    ListGroup.li [ ListGroup.attrs [ Flex.block, Flex.justifyBetween, Flex.alignItemsCenter ] ] <|
        [ Button.button [ Button.roleLink, Button.attrs [ clickEv ] ] [ text name ]
        , ButtonGroup.buttonGroup
            [ ButtonGroup.small ]
          <|
            case scanned of
                ScanFound ->
                    []

                _ ->
                    [ ButtonGroup.button
                        [ Button.disabled <| isJust scanningOn
                        , Button.primary
                        , Button.onClick <| ScanGames path
                        ]
                      <|
                        scanningSpinner path scanningOn "Scan" "Scanning..."
                    ]
        ]


gameFolderElement : Maybe String -> String -> ScanStatus -> ListGroup.Item Msg
gameFolderElement scanningOn name scanned =
    ListGroup.li [ ListGroup.attrs [ Flex.block, Flex.justifyBetween, Flex.alignItemsCenter ] ]
        [ text name
        , ButtonGroup.buttonGroup
            [ ButtonGroup.small ]
          <|
            case scanned of
                ScanFound ->
                    [ ButtonGroup.button
                        [ Button.disabled <| isJust scanningOn
                        , Button.primary
                        , Button.onClick <| ScanGames name
                        ]
                      <|
                        scanningSpinner name scanningOn "Rescan" "Rescanning..."
                    , ButtonGroup.button
                        [ Button.disabled <| isJust scanningOn
                        , Button.primary
                        , Button.onClick <| DeleteGameScan name
                        ]
                        [ text "Discard" ]
                    ]

                _ ->
                    [ ButtonGroup.button
                        [ Button.disabled <| isJust scanningOn
                        , Button.primary
                        , Button.onClick <| ScanGames name
                        ]
                      <|
                        scanningSpinner name scanningOn "Scan" "Scanning..."
                    ]
        ]


loadScriptEncoder : ContentLoadInfo -> Value
loadScriptEncoder info =
    scriptCallEncoder
        [ ( "method", Encode.string info.method )
        , ( "core_codename", Encode.string info.coreCodeName )
        , ( "core_path", Encode.string info.corePath )
        , ( "rom", Encode.string info.rom )
        , ( "is_zip", Encode.bool info.isZip )
        ]
        info.script


scriptCallEncoder : List ( String, Value ) -> String -> Value
scriptCallEncoder params source =
    Encode.object
        [ ( "params", Encode.object params )
        , ( "source", Encode.string source )
        ]

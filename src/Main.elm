port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


port sendStuff : Json.Encode.Value -> Cmd msg


port receiveStuff : (Json.Encode.Value -> msg) -> Sub msg


port signIn : () -> Cmd msg


port signInInfo : (Json.Encode.Value -> msg) -> Sub msg



---- MODEL ----


type alias UserData =
    { token : String, email : String }


type alias Model =
    { counter : Int, userData : Maybe UserData, error : String }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0, userData = Maybe.Nothing, error = "No error" }, Cmd.none )



---- UPDATE ----


type Msg
    = LogIn
    | SendData
    | Received (Result Json.Decode.Error Int)
    | LoggedInData (Result Json.Decode.Error UserData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SendData ->
            ( model, sendStuff <| Json.Encode.string "test" )

        LogIn ->
            ( model, signIn () )

        Received result ->
            case result of
                Ok value ->
                    ( { model | counter = value }, Cmd.none )

                Err error ->
                    ( { model | error = Json.Decode.errorToString error }, Cmd.none )

        LoggedInData result ->
            case result of
                Ok value ->
                    ( { model | userData = Just value }, Cmd.none )

                Err error ->
                    ( { model | error = Json.Decode.errorToString error }, Cmd.none )


valueDecoder : Json.Decode.Decoder Int
valueDecoder =
    Json.Decode.field "value" Json.Decode.int


userDataDecoder : Json.Decode.Decoder UserData
userDataDecoder =
    Json.Decode.succeed UserData
        |> Json.Decode.Pipeline.required "token" Json.Decode.string
        |> Json.Decode.Pipeline.required "email" Json.Decode.string



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , button [ onClick SendData ] [ text "Send some data" ]
        , button [ onClick LogIn ] [ text "Login with Google" ]
        , h2 [] [ text <| String.fromInt model.counter ]
        , h2 [] [ text model.error ]
        , h2 []
            [ text <|
                case model.userData of
                    Just data ->
                        data.email ++ " " ++ data.token

                    Maybe.Nothing ->
                        ""
            ]
        ]



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions model =
    -- always Sub.none
    Sub.batch
        [ receiveStuff (Json.Decode.decodeValue valueDecoder >> Received)
        , signInInfo (Json.Decode.decodeValue userDataDecoder >> LoggedInData)
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }

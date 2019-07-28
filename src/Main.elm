port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, img, text)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode


port sendStuff : Json.Encode.Value -> Cmd msg


port receiveStuff : (Json.Encode.Value -> msg) -> Sub msg



---- MODEL ----


type alias Model =
    { counter : Int, error : String }


init : ( Model, Cmd Msg )
init =
    ( { counter = 0, error = "No error" }, Cmd.none )



---- UPDATE ----


type Msg
    = LogIn
    | Received (Result Json.Decode.Error Int)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn ->
            ( model, sendStuff <| Json.Encode.string "test" )

        Received result ->
            case result of
                Ok value ->
                    ( { model | counter = value }, Cmd.none )

                Err error ->
                    ( { model | error = Json.Decode.errorToString error }, Cmd.none )


valueDecoder : Json.Decode.Decoder Int
valueDecoder =
    Json.Decode.field "value" Json.Decode.int



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , button [ onClick LogIn ] [ text "Login" ]
        , h2 [] [ text <| String.fromInt model.counter ]
        , h2 [] [ text model.error ]
        ]



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions model =
    -- always Sub.none
    receiveStuff (Json.Decode.decodeValue valueDecoder >> Received)


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }

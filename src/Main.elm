port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, button, div, h1, h2, h3, img, input, p, text)
import Html.Attributes exposing (placeholder, src, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


port signIn : () -> Cmd msg


port signInInfo : (Json.Encode.Value -> msg) -> Sub msg


port signInError : (Json.Encode.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port saveMessage : Json.Encode.Value -> Cmd msg


port receiveMessages : (Json.Encode.Value -> msg) -> Sub msg



---- MODEL ----


type alias MessageContent =
    { uid : String, content : String }


type alias ErrorData =
    { code : Maybe String, message : Maybe String, credential : Maybe String }


type alias UserData =
    { token : String, email : String, uid : String }


type alias Model =
    { userData : Maybe UserData, error : ErrorData, inputContent : String, messages : List String }


init : ( Model, Cmd Msg )
init =
    ( { userData = Maybe.Nothing, error = emptyError, inputContent = "", messages = [] }, Cmd.none )



---- UPDATE ----


type Msg
    = LogIn
    | LogOut
    | LoggedInData (Result Json.Decode.Error UserData)
    | LoggedInError (Result Json.Decode.Error ErrorData)
    | SaveMessage
    | InputChanged String
    | MessagesReceived (Result Json.Decode.Error (List String))


emptyError : ErrorData
emptyError =
    { code = Maybe.Nothing, credential = Maybe.Nothing, message = Maybe.Nothing }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn ->
            ( model, signIn () )

        LogOut ->
            ( { model | userData = Maybe.Nothing, error = emptyError }, signOut () )

        LoggedInData result ->
            case result of
                Ok value ->
                    ( { model | userData = Just value }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError <| Json.Decode.errorToString error }, Cmd.none )

        LoggedInError result ->
            case result of
                Ok value ->
                    ( { model | error = value }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError <| Json.Decode.errorToString error }, Cmd.none )

        SaveMessage ->
            ( model, saveMessage <| messageEncoder model )

        InputChanged value ->
            ( { model | inputContent = value }, Cmd.none )

        MessagesReceived result ->
            case result of
                Ok value ->
                    ( { model | messages = value }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError <| Json.Decode.errorToString error }, Cmd.none )


messageEncoder : Model -> Json.Encode.Value
messageEncoder model =
    Json.Encode.object
        [ ( "content", Json.Encode.string model.inputContent )
        , ( "uid"
          , case model.userData of
                Just userData ->
                    Json.Encode.string userData.uid

                Maybe.Nothing ->
                    Json.Encode.null
          )
        ]


messageToError : String -> ErrorData
messageToError message =
    { code = Maybe.Nothing, credential = Maybe.Nothing, message = Just message }


errorPrinter : ErrorData -> String
errorPrinter errorData =
    Maybe.withDefault "" errorData.code ++ " " ++ Maybe.withDefault "" errorData.credential ++ " " ++ Maybe.withDefault "" errorData.message


userDataDecoder : Json.Decode.Decoder UserData
userDataDecoder =
    Json.Decode.succeed UserData
        |> Json.Decode.Pipeline.required "token" Json.Decode.string
        |> Json.Decode.Pipeline.required "email" Json.Decode.string
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string


logInErrorDecoder : Json.Decode.Decoder ErrorData
logInErrorDecoder =
    Json.Decode.succeed ErrorData
        |> Json.Decode.Pipeline.required "code" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.Pipeline.required "message" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.Pipeline.required "credential" (Json.Decode.nullable Json.Decode.string)


messagesDecoder =
    Json.Decode.decodeString (Json.Decode.list Json.Decode.string)


messageListDecoder : Json.Decode.Decoder (List String)
messageListDecoder =
    Json.Decode.succeed identity
        |> Json.Decode.Pipeline.required "messages" (Json.Decode.list Json.Decode.string)



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , case model.userData of
            Just data ->
                button [ onClick LogOut ] [ text "Logout from Google" ]

            Maybe.Nothing ->
                button [ onClick LogIn ] [ text "Login with Google" ]
        , h2 []
            [ text <|
                case model.userData of
                    Just data ->
                        data.email ++ " " ++ data.uid ++ " " ++ data.token

                    Maybe.Nothing ->
                        ""
            ]
        , case model.userData of
            Just data ->
                div []
                    [ input [ placeholder "Message to save", value model.inputContent, onInput InputChanged ] []
                    , button [ onClick SaveMessage ] [ text "Save new message" ]
                    ]

            Maybe.Nothing ->
                div [] []
        , div []
            [ h3 []
                [ text "Previous messages"
                , div [] <|
                    List.map
                        (\m -> p [] [ text m ])
                        model.messages
                ]
            ]
        , h2 [] [ text <| errorPrinter model.error ]
        ]



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ signInInfo (Json.Decode.decodeValue userDataDecoder >> LoggedInData)
        , signInError (Json.Decode.decodeValue logInErrorDecoder >> LoggedInError)
        , receiveMessages (Json.Decode.decodeValue messageListDecoder >> MessagesReceived)
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }

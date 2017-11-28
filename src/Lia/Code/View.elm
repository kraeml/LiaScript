module Lia.Code.View exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onDoubleClick, onInput)
import Lia.Code.Model exposing (Model)
import Lia.Code.Types exposing (Code(..))
import Lia.Code.Update exposing (Msg(..))
import Lia.Helper as Array2D
import Lia.Utils


view : Model -> Code -> Html Msg
view model code =
    case code of
        Highlight lang block ->
            highlight lang block Nothing

        Evaluate lang idx x ->
            case Array2D.get idx model of
                Just elem ->
                    Html.div [ Attr.class "lia-code-eval" ]
                        [ if elem.editing then
                            Html.textarea
                                [ Attr.style [ ( "width", "100%" ) ]
                                , Attr.class "lia-input"
                                , elem.code |> String.lines |> List.length |> Attr.rows
                                , onInput <| Update idx
                                , Attr.value elem.code
                                , onDoubleClick (FlipMode idx)
                                ]
                                []
                          else
                            highlight lang elem.code (Just idx)
                        , Html.div []
                            [ if elem.running then
                                Html.button [ Attr.class "lia-btn lia-icon" ]
                                    [ Html.text "settings" ]
                              else
                                Html.button [ Attr.class "lia-btn lia-icon", onClick (Eval idx x) ]
                                    [ Html.text "play_circle_filled" ]
                            , Html.span [ Attr.class "lia-spacer" ] []
                            , Html.button
                                [ (elem.version_active - 1)
                                    |> Load idx
                                    |> onClick
                                , Attr.class "lia-btn lia-icon lia-left"
                                ]
                                [ Html.text "navigate_before" ]
                            , Html.span [ Attr.class "lia-label lia-left" ] [ Html.text (toString elem.version_active) ]
                            , Html.button
                                [ (elem.version_active + 1)
                                    |> Load idx
                                    |> onClick
                                , Attr.class "lia-btn lia-icon lia-left"
                                ]
                                [ Html.text "navigate_next" ]
                            ]
                        , case elem.result of
                            Ok rslt ->
                                Html.pre [] [ Lia.Utils.stringToHtml rslt ]

                            Err rslt ->
                                Html.pre [ Attr.style [ ( "color", "red" ) ] ] [ Html.text ("Error: " ++ rslt) ]
                        ]

                Nothing ->
                    Html.text ""


highlight : String -> String -> Maybe Array2D.ID2 -> Html Msg
highlight lang code idx =
    Html.pre
        (case idx of
            Nothing ->
                [ Attr.class "lia-code" ]

            Just idx_ ->
                [ Attr.class "lia-code", onDoubleClick (FlipMode idx_) ]
        )
        [ Html.code [ Attr.class "lia-code-highlight" ]
            [ Lia.Utils.highlight lang code ]
        ]

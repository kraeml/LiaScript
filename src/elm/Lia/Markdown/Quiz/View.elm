module Lia.Markdown.Quiz.View exposing (view, view_solution)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Lia.Markdown.Inline.Types exposing (MultInlines)
import Lia.Markdown.Inline.View exposing (view_inf)
import Lia.Markdown.Quiz.Block.View as Block
import Lia.Markdown.Quiz.Matrix.View as Matrix
import Lia.Markdown.Quiz.Model exposing (get_state)
import Lia.Markdown.Quiz.Types
    exposing
        ( Element
        , Quiz
        , Solution(..)
        , State(..)
        , Type(..)
        , Vector
        , solved
        )
import Lia.Markdown.Quiz.Update exposing (Msg(..))
import Lia.Markdown.Quiz.Vector.View as Vector
import Translations exposing (Lang, quizCheck, quizChecked, quizResolved, quizSolution)


view : Lang -> Quiz -> Vector -> Html Msg
view lang quiz vector =
    case get_state vector quiz.id of
        Just elem ->
            state_view (solved elem) elem.state quiz
                |> view_quiz lang elem quiz

        _ ->
            Html.text ""


state_view : Bool -> State -> Quiz -> Html Msg
state_view solved state quiz =
    case ( state, quiz.quiz ) of
        ( Block_State s, Block_Type q ) ->
            s
                |> Block.view solved q
                |> Html.map (Block_Update quiz.id)

        ( Vector_State s, Vector_Type q ) ->
            s
                |> Vector.view solved q
                |> Html.map (Vector_Update quiz.id)

        ( Matrix_State s, Matrix_Type q ) ->
            s
                |> Matrix.view solved q
                |> Html.map (Matrix_Update quiz.id)

        _ ->
            Html.text ""


view_quiz : Lang -> Element -> Quiz -> Html Msg -> Html Msg
view_quiz lang state quiz fn =
    Html.p []
        [ if state.error_msg == "" then
            Html.text ""

          else
            Html.br [] []
        , if state.error_msg == "" then
            Html.text ""

          else
            Html.text state.error_msg
        , fn
        , view_button lang state.trial state.solved (Check quiz.id quiz.quiz quiz.javascript)
        , if quiz.quiz == Empty_Type then
            Html.text ""

          else
            view_button_solution lang state.solved (ShowSolution quiz.id quiz.quiz)
        , view_hints quiz.id state.hint quiz.hints
        ]


view_button_solution : Lang -> Solution -> Msg -> Html Msg
view_button_solution lang solution msg =
    if solution == Open then
        Html.span
            [ Attr.class "lia-hint-btn"
            , onClick msg
            , Attr.title (quizSolution lang)
            , Attr.style "cursor" "pointer"
            ]
            [ Html.text "info" ]

    else
        Html.text ""


view_button : Lang -> Int -> Solution -> Msg -> Html Msg
view_button lang trials solved msg =
    case solved of
        Open ->
            if trials == 0 then
                Html.button [ Attr.class "lia-btn", onClick msg ] [ Html.text (quizCheck lang) ]

            else
                Html.button
                    [ Attr.class "lia-btn", Attr.class "lia-failure", onClick msg ]
                    [ Html.text (quizCheck lang ++ " " ++ String.fromInt trials) ]

        Solved ->
            Html.button
                [ Attr.class "lia-btn", Attr.class "lia-success", Attr.disabled True ]
                [ Html.text (quizChecked lang ++ " " ++ String.fromInt trials) ]

        ReSolved ->
            Html.button
                [ Attr.class "lia-btn", Attr.class "lia-warning", Attr.disabled True ]
                [ Html.text (quizResolved lang) ]


view_hints : Int -> Int -> MultInlines -> Html Msg
view_hints idx counter hints =
    let
        v_hints h c =
            case ( h, c ) of
                ( [], _ ) ->
                    []

                ( _, 0 ) ->
                    []

                ( x :: xs, _ ) ->
                    Html.p []
                        (Html.span [ Attr.class "lia-icon" ] [ Html.text "lightbulb_outline" ]
                            :: List.map view_inf x
                        )
                        :: v_hints xs (c - 1)
    in
    if counter < List.length hints then
        Html.span []
            [ Html.text " "
            , Html.span
                [ Attr.class "lia-hint-btn"
                , onClick (ShowHint idx)
                , Attr.title "show hint"
                , Attr.style "cursor" "pointer"
                ]
                [ Html.text "help" ]
            , Html.div
                [ Attr.class "lia-hints"
                ]
                (v_hints hints counter)
            ]

    else
        Html.div
            [ Attr.class "lia-hints"
            ]
            (v_hints hints counter)


view_solution : Vector -> Quiz -> ( Bool, Bool )
view_solution vector quiz =
    quiz.id
        |> get_state vector
        |> Maybe.map solved
        |> Maybe.withDefault False
        |> Tuple.pair (quiz.quiz == Empty_Type)

module Lia.Quiz.Parser exposing (quiz)

import Combine exposing (..)
import Lia.Inline.Parser exposing (..)
import Lia.Inline.Types exposing (..)
import Lia.PState exposing (PState)
import Lia.Quiz.Types exposing (Quiz(..), QuizBlock)


quiz : Parser PState QuizBlock
quiz =
    let
        counter =
            let
                pp par =
                    succeed par.quiz

                increment_counter c =
                    { c | quiz = c.quiz + 1 }
            in
            withState pp <* modifyState increment_counter
    in
    QuizBlock <$> choice [ quiz_SingleChoice, quiz_MultipleChoice, quiz_TextInput ] <*> counter <*> quiz_hints


quiz_TextInput : Parser s Quiz
quiz_TextInput =
    TextInput <$> (regex "[ \\t]*\\[\\[" *> regex "[^\n\\]]+" <* regex "\\]\\]( *)\\n")


quiz_SingleChoice : Parser PState Quiz
quiz_SingleChoice =
    let
        get_result list =
            list
                |> List.indexedMap (,)
                |> List.filter (\( _, ( rslt, _ ) ) -> rslt == True)
                |> (\l ->
                        case List.head l of
                            Just ( i, _ ) ->
                                i

                            Nothing ->
                                -1
                   )
    in
    many (checked False (regex "[ \\t]*\\[\\( \\)\\]"))
        |> map (\a b -> List.append a [ b ])
        |> andMap (checked True (regex "[ \\t]*\\[\\(X\\)\\]"))
        |> map (++)
        |> andMap (many (checked False (regex "[ \\t]*\\[\\( \\)\\]")))
        |> map (\q -> SingleChoice (get_result q) (List.map (\( _, qq ) -> qq) q))


checked : Bool -> Parser PState res -> Parser PState ( Bool, List Inline )
checked b p =
    (\l -> ( b, l )) <$> (p *> line <* newline)


quiz_hints : Parser PState (List (List Inline))
quiz_hints =
    many (regex "[ \\t]*\\[\\[\\?\\]\\]" *> line <* newline)


quiz_MultipleChoice : Parser PState Quiz
quiz_MultipleChoice =
    MultipleChoice
        <$> many1
                (choice
                    [ checked True (regex "[ \\t]*\\[\\[X\\]\\]")
                    , checked False (regex "[ \\t]*\\[\\[ \\]\\]")
                    ]
                )
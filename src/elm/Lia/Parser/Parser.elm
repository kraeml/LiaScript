module Lia.Parser.Parser exposing
    ( formatError
    , parse_defintion
    , parse_section
    , parse_titles
    )

import Combine
    exposing
        ( InputStream
        , currentLocation
        , ignore
        , keep
        , or
        , regex
        , string
        , withColumn
        )
import Combine.Char exposing (anyChar)
import Lia.Definition.Parser
import Lia.Definition.Types exposing (Definition)
import Lia.Markdown.Parser as Markdown
import Lia.Parser.Context exposing (init)
import Lia.Parser.Helper exposing (stringTill)
import Lia.Parser.Preprocessor as Preprocessor
import Lia.Section as Section exposing (Section)


parse_defintion : String -> String -> Result String ( Definition, ( String, Int ) )
parse_defintion base code =
    case
        Combine.runParser
            (Lia.Definition.Parser.parse
                |> ignore
                    (or (string "#")
                        (stringTill (regex "\n#"))
                    )
            )
            (base
                |> Lia.Definition.Types.default
                |> init identity 0
            )
            code
    of
        Ok ( state, data, line ) ->
            Ok ( state.defines, ( "#" ++ data.input, line ) )

        Err ( _, stream, ms ) ->
            Err (formatError ms stream)


parse_titles : Int -> Definition -> String -> Result String ( Section.Base, ( String, Int ) )
parse_titles editor_line defines code =
    case Combine.runParser Preprocessor.section (init identity editor_line defines) code of
        Ok ( _, data, ( rslt, line ) ) ->
            Ok ( rslt, ( data.input, line ) )

        Err ( _, stream, ms ) ->
            Err (formatError ms stream)


parse_section :
    (String -> String)
    -> Definition
    -> Section
    -> Result String Section
parse_section search_index global section =
    case
        Combine.runParser
            (Lia.Definition.Parser.parse |> keep Markdown.run)
            (init search_index section.editor_line { global | section = section.idx })
            section.code
    of
        Ok ( state, _, es ) ->
            Ok
                { section
                    | body = es
                    , error = Nothing
                    , visited = True
                    , code_vector = state.code_vector
                    , quiz_vector = state.quiz_vector
                    , survey_vector = state.survey_vector
                    , effect_model = state.effect_model
                    , footnotes = state.footnotes
                    , definition =
                        if state.defines_updated then
                            Just state.defines

                        else
                            Nothing
                    , parsed = True
                }

        Err ( _, stream, ms ) ->
            formatError ms stream |> Err


formatError : List String -> InputStream -> String
formatError ms stream =
    let
        location =
            currentLocation stream

        separator =
            "|> "

        expectationSeparator =
            "\n  * "

        --        lineNumberOffset =
        --            floor (logBase 10 (toFloat location.line)) + 1
        separatorOffset =
            String.length separator

        padding =
            location.column + separatorOffset + 2
    in
    "Parse error around line:\\n\\n"
        ++ String.fromInt location.line
        ++ separator
        ++ location.source
        ++ "\\n"
        ++ String.padLeft padding ' ' "^"
        ++ "\\nI expected one of the following:\\n"
        ++ expectationSeparator
        ++ String.join expectationSeparator ms

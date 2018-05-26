module Lia.Markdown.Footnote.Model exposing (..)

import Dict exposing (Dict)
import Lia.Markdown.Types exposing (MarkdownS)


type alias Model =
    Dict String MarkdownS


init : Model
init =
    Dict.empty


insert : String -> MarkdownS -> Model -> Model
insert key val model =
    Dict.insert key val model


toList : Model -> List ( String, MarkdownS )
toList =
    Dict.toList


empty : Model -> Bool
empty =
    Dict.isEmpty


getNote : String -> Model -> Maybe MarkdownS
getNote key model =
    Dict.get key model
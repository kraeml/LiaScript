module Lia.Markdown.Footnote.Parser exposing (block, inline)

import Combine exposing (..)
import Lia.Helper exposing (..)
import Lia.Markdown.Footnote.Model as Model
import Lia.Markdown.Inline.Types exposing (..)
import Lia.Markdown.Types exposing (Markdown(..))
import Lia.PState exposing (PState, identation_append)


inline : Parser PState (Annotation -> Inline)
inline =
    ((,)
        <$> (string "[^" *> stringTill (string "]"))
        <*> maybe (string "(" *> stringTill (string ")"))
    )
        >>= store


block : Parser PState (List Markdown) -> Parser PState ()
block p =
    ((,)
        <$> (string "[^" *> stringTill (string "]:"))
        <*> (identation_append "   " *> p)
    )
        >>= add_footnote


store : ( String, Maybe String ) -> Parser PState (Annotation -> Inline)
store ( key, val ) =
    case val of
        Just v ->
            add_footnote ( key, [ Paragraph Nothing [ Chars v Nothing ] ] )
                *> succeed (FootnoteMark key)

        _ ->
            succeed (FootnoteMark key)


add_footnote : ( String, List Markdown ) -> Parser PState ()
add_footnote ( key, val ) =
    modifyState (\s -> { s | footnotes = Model.insert key val s.footnotes })
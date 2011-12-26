{-# LANGUAGE OverloadedStrings #-}

module Dummy where

import qualified Blaze.ByteString.Builder.Char.Utf8 as B
import Data.CaseInsensitive
import qualified Data.Enumerator as E
import qualified Network.Wai as Wai
import qualified Network.HTTP.Types as HTTP.Types

dummy :: Wai.Application
dummy _ =
  E.Iteratee $ do return response
  where
    response = E.Continue $ buildResponse ""
      where
        buildResponse responseSoFar (E.Chunks _) = E.Iteratee $ return $ E.Continue $ buildResponse responseSoFar
        buildResponse _ E.EOF = E.Iteratee $ return $ E.Yield responseBuilder E.EOF
    responseBuilder :: Wai.Response
    responseBuilder = Wai.ResponseBuilder status headers sayHello
    sayHello = B.fromString "hello 조선 :D"
    status = HTTP.Types.status200
    headers = [("Content-Type" :: CI HTTP.Types.Ascii, "text/html; charset=utf-8" :: HTTP.Types.Ascii)]

  
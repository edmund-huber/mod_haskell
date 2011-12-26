{-# LANGUAGE OverloadedStrings #-}

module Dummy where

import qualified Blaze.ByteString.Builder.Char.Utf8 as B
import qualified Data.ByteString.Char8 as C8
import Data.CaseInsensitive
import qualified Data.Enumerator as E
import qualified Network.Wai as Wai
import qualified Network.HTTP.Types as HTTP.Types

dummy :: Wai.Application
dummy r =
  E.Iteratee $ do return response
  where
    response = E.Continue $ buildResponse ""
      where
        buildResponse responseSoFar (E.Chunks _) = E.Iteratee $ return $ E.Continue $ buildResponse responseSoFar
        buildResponse _ E.EOF = E.Iteratee $ return $ E.Yield responseBuilder E.EOF
    responseBuilder :: Wai.Response
    responseBuilder = Wai.ResponseBuilder status headers sayHello
    sayHello = B.fromString $
               foldr (\(name, dec) ss -> name ++ " = " ++ (dec r) ++ "<br>" ++ ss) "" [
                 ("requestMethod", show . Wai.requestMethod),
                 ("httpVersion", show . Wai.httpVersion),
                 ("rawPathInfo", show . Wai.rawPathInfo),
                 ("rawQueryString", show . Wai.rawQueryString),
                 ("serverName", show . Wai.serverName),
                 ("serverPort", show . Wai.serverPort),
                 ("requestHeaders", show . Wai.requestHeaders),
                 ("isSecure", show . Wai.isSecure),
                 ("remoteHost", show . Wai.remoteHost),
                 ("pathInfo", show . Wai.pathInfo),
                 ("queryString", show . Wai.queryString)
                 ] ++ "UTF-8 test: 조선"
    status = HTTP.Types.status200
    headers = [("Content-Type" :: CI HTTP.Types.Ascii, "text/html; charset=utf-8" :: HTTP.Types.Ascii)]

  
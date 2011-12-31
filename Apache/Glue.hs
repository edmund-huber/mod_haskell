{-# LANGUAGE ForeignFunctionInterface, OverloadedStrings #-}

module Apache.Glue where

import qualified Apache.Request
import qualified Apr.Network.IO
import Apr.Tables
import Blaze.ByteString.Builder
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as B8
import qualified Data.CaseInsensitive as CI
import qualified Data.Enumerator as E
import qualified Data.Text as T
import Data.Word
import Foreign.C.String
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Array
import qualified Network.HTTP.Types as HTTP.Types
import qualified Network.Socket as S
import qualified Network.Wai as Wai

-- Put any WAI application here..
import Dummy (dummy)
app :: Wai.Application
app = dummy

feedApacheRequestToApplication :: Ptr Apache.Request.Request -> IO ()
feedApacheRequestToApplication ptr =
  do
    request <- peek ptr
    let clientPort = Apr.Network.IO.port . Apache.Request.remoteAddr . Apache.Request.connection $ request
    let method = Apache.Request.method request
    let protoNum = fromIntegral $ Apache.Request.protoNum request
    let httpMajor = protoNum `quot` 1000
    let httpMinor = protoNum `mod` 1000
    requestHeaders <- fmap (map $ \(k, v) -> (CI.mk $ B8.pack k, B8.pack v)) $ fromAprTable (Apache.Request.headersIn request)
    let waiRequest = Wai.Request {
          Wai.requestMethod = case HTTP.Types.parseMethod method of
             -- should probably do something with Left ..
             Right m -> HTTP.Types.renderStdMethod m,
          Wai.httpVersion = HTTP.Types.HttpVersion {
            HTTP.Types.httpMajor = httpMajor,
            HTTP.Types.httpMinor = httpMinor
            },
          Wai.rawPathInfo = Apache.Request.unparsedUri request,
          Wai.rawQueryString = case B8.split '?' $ Apache.Request.unparsedUri request of
            _:parts@(_:qs) -> B8.concat $ ["?"] ++ parts
            _ -> B8.empty,
          Wai.serverName = Apache.Request.hostname request,
          Wai.serverPort = fromIntegral $ (Apache.Request.port . Apache.Request.server) request,
          Wai.requestHeaders = requestHeaders,
          Wai.isSecure = False,
          Wai.remoteHost = case Apr.Network.IO.sin . Apache.Request.remoteAddr . Apache.Request.connection $ request of
            Apr.Network.IO.SockAddrInInet {Apr.Network.IO.sinAddr=sinAddr} ->
              S.SockAddrInet (S.PortNum clientPort) (Apr.Network.IO.sAddr sinAddr)
            Apr.Network.IO.SockAddrInInet6 -> error "not supporting inet6 yet",
          Wai.pathInfo = filter (not . T.null) $ case B8.split '?' $ Apache.Request.unparsedUri request of
            path:_ -> map (T.pack . B8.unpack) $ B8.split '/' path
            _ -> [],
          Wai.queryString =
            let
              expectKv (k:(v:[])) = (k, Just v)
              expectKv (k:[]) = (k, Nothing)
              expectKv _ = error "bad"
            in case B8.split '?' $ Apache.Request.unparsedUri request of
              _:parts@(_:qs) -> map (expectKv . B8.split '=') (B8.split '&' $ B8.concat parts)
              _ -> []
          }
    result <- E.run $ app waiRequest
    case result of
      Left exc -> error "some sort of error.."
      Right resp -> case resp of
        Wai.ResponseBuilder status headers builder -> do
          -- some headers go into the list of headers, others are special
          mapM_ (\(k, v) -> let
                    unfoldedK = CI.foldedCase k
                    in case unfoldedK of
                      "content-type" -> withArray0 0 (B.unpack v) (\p_v -> set_content_type ptr p_v)
                      _ -> withArray0 0 (B.unpack unfoldedK) (\p_k ->
                                                               (withArray0 0 (B.unpack v) (\p_v ->
                                                                                            apr_table_add (Apache.Request.headersIn request) p_k p_v
                                                                                          )))
                ) headers
          -- write the response body to the apache request structure
          toByteStringIO (\bs -> withArray0 0 (B.unpack bs) (\p -> ap_rputs p ptr)) builder

foreign import ccall "/usr/include/apr-1.0/apr_tables.h apr_table_add" apr_table_add :: Ptr a -> Ptr Word8 -> Ptr Word8 -> IO ()
foreign import ccall "/usr/include/apache2/http_protocol.h ap_rputs" ap_rputs :: Ptr Word8 -> Ptr a -> IO ()
foreign import ccall "mod_haskell.c set_content_type" set_content_type :: Ptr a -> Ptr Word8 -> IO ()

foreign export ccall feedApacheRequestToApplication :: Ptr Apache.Request.Request -> IO ()

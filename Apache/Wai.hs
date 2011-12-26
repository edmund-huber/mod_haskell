{-# LANGUAGE ForeignFunctionInterface, OverloadedStrings #-}

module Apache.Wai where

import Blaze.ByteString.Builder
import Data.ByteString as B
import Data.ByteString.Char8 as B8
import qualified Data.Enumerator as E
import qualified Data.CaseInsensitive as CI
import Data.Word
import Foreign.C.String
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Marshal.Array
import qualified Network.HTTP.Types as HTTP.Types
import qualified Network.Socket as S
import qualified Network.Wai as Wai

-- Put any WAI application here..
import Dummy (dummy)
app :: Wai.Application
app = dummy

feedApacheRequestToApplication :: CString -> CInt -> Word32 -> Word16 -> CString -> CInt -> CInt -> CString -> Ptr a -> Ptr a -> IO ()
feedApacheRequestToApplication cServerName cServerPort cClientHost cClientPort cMethod cHttpMajor cHttpMinor cFullPath apacheRequest apacheRequestHeaders =
  do
    method <- B8.packCString cMethod
    fullPath <- B8.packCString cFullPath
    serverName <- B8.packCString cServerName
    let waiRequest = Wai.Request {
          Wai.requestMethod = case HTTP.Types.parseMethod method of
             -- should probably do something with Left ..
             Right m -> HTTP.Types.renderStdMethod m,
          Wai.httpVersion = HTTP.Types.HttpVersion {
            HTTP.Types.httpMajor = fromIntegral cHttpMajor,
            HTTP.Types.httpMinor = fromIntegral cHttpMinor
            },
          Wai.rawPathInfo = fullPath,
          Wai.rawQueryString = case B8.split '?' fullPath of
            _:parts@(_:qs) -> B8.concat $ ["?"] ++ parts
            _ -> B8.empty,
          Wai.serverName = serverName,
          Wai.serverPort = fromIntegral cServerPort,
          Wai.requestHeaders = [],
          Wai.isSecure = False,
          Wai.remoteHost = S.SockAddrInet (S.PortNum cClientPort) cClientHost,
          Wai.pathInfo = [],
          Wai.queryString = []
          }
    result <- E.run $ app waiRequest
    case result of
      -- Left exc -> 
      Right resp -> case resp of
        Wai.ResponseBuilder status headers builder -> do
          -- some headers go into the list of headers, others are special
          mapM_ (\(k, v) -> let
                    unfoldedK = CI.foldedCase k
                    in case unfoldedK of
                      "content-type" -> withArray0 0 (B.unpack v) (\p_v -> set_content_type apacheRequest p_v)
                      _ -> withArray0 0 (B.unpack unfoldedK) (\p_k ->
                                                               (withArray0 0 (B.unpack v) (\p_v ->
                                                                                            apr_table_add apacheRequestHeaders p_k p_v
                                                                                          )))
                ) headers
          -- write the response body to the apache request structure
          toByteStringIO (\bs -> withArray (B.unpack bs) (\p -> ap_rputs p apacheRequest)) builder

foreign import ccall "/usr/include/apache2/http_protocol.h ap_rputs" ap_rputs :: Ptr Word8 -> Ptr a -> IO ()
foreign import ccall "/usr/include/apache2/http_protocol.h apr_table_add" apr_table_add :: Ptr a -> Ptr Word8 -> Ptr Word8 -> IO ()
foreign import ccall "mod_wai.c set_content_type" set_content_type :: Ptr a -> Ptr Word8 -> IO ()

foreign export ccall feedApacheRequestToApplication :: CString -> CInt -> Word32 -> Word16 -> CString -> CInt -> CInt -> CString -> Ptr a -> Ptr a -> IO ()
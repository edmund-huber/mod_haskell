{-# LANGUAGE ForeignFunctionInterface #-}

module Apache.Request (
  handledOK, handledDeclined, handledDone,
  Request(..),
  Connection(..),
  Server(..)
  ) where

import qualified Apr.Network.IO
import qualified Apr.Tables
import qualified Apr.Uri

import Control.Monad
import Data.ByteString
import Data.Word
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable

#include <apache2/httpd.h>

data HandledStatus = HandledStatus CInt

handledOK :: HandledStatus
handledOK = HandledStatus (#{const OK})

handledDeclined :: HandledStatus
handledDeclined = HandledStatus (#{const DECLINED})

handledDone :: HandledStatus
handledDone = HandledStatus (#{const DONE})

data Request = Request {
  -- The connection to the client
  connection :: Connection,
  -- The virtual host for this request
  server :: Server,
  -- Protocol version number of protocol; 1.1 = 1001
  protoNum :: CInt,
  -- Host, as set by full URI or Host:
  hostname :: ByteString,
  -- Request method (eg. GET, HEAD, POST, etc.)
  method :: ByteString,
  -- MIME header environment from the request
  headersIn :: Ptr Apr.Tables.Header,
  -- MIME header environment for the response
  headersOut :: Ptr Apr.Tables.Header,
  -- The content-type for the current request
  contentType :: Ptr CChar,
  -- How to encode the data
  contentEncoding :: Ptr CChar,
  -- Array of strings representing the content languages
  contentLanguages :: Ptr Apr.Tables.Header,
  -- The URI without any parsing performed
  unparsedUri :: ByteString
  }

data Connection = Connection {
    -- local address
    localAddr :: Apr.Network.IO.SockAddr,
    -- remote address
    remoteAddr :: Apr.Network.IO.SockAddr
    }

data Server = Server {
  -- for redirects, etc.
  port :: #type apr_port_t
  }

instance Storable Request where
  sizeOf _ = (#size request_rec)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    connection <- (#peek request_rec, connection) >=> peek $ ptr
    server <- (#peek request_rec, server) ptr
    protoNum <- (#peek request_rec, proto_num) ptr
    hostname <- (#peek request_rec, hostname) >=> packCString $ ptr
    method <- (#peek request_rec, method) >=> packCString $ ptr
    headersIn <- (#peek request_rec, headers_in) ptr
    headersOut <- (#peek request_rec, headers_out) ptr
    contentType <- (#peek request_rec, content_type) ptr
    contentEncoding <- (#peek request_rec, content_encoding) ptr
    contentLanguages <- (#peek request_rec, content_languages) ptr
    unparsedUri <- (#peek request_rec, unparsed_uri) >=> packCString $ ptr
    return $ Request connection server protoNum hostname method headersIn headersOut
      contentType contentEncoding contentLanguages unparsedUri

instance Storable Connection where
  sizeOf _ = (#size conn_rec)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    localAddr <- (#peek conn_rec, local_addr) >=> peek $ ptr
    remoteAddr <- (#peek conn_rec, remote_addr) >=> peek $ ptr
    return $ Connection localAddr remoteAddr
    
instance Storable Server where
  sizeOf _ = (#size server_rec)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    port <- (#peek server_rec, port) ptr
    return $ Server port

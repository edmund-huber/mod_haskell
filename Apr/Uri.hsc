{-# LANGUAGE ForeignFunctionInterface #-}

module Apr.Uri (
  Uri(..)
  ) where 

import Data.Word
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable

#include <apr-1.0/apr_uri.h>

data Uri = Uri {
  -- scheme ("http"/"ftp"/...)
  scheme :: Ptr CChar,
  -- combined [user[:password]\@]host[:port]
  hostinfo :: Ptr CChar,
  -- user name, as in http://user:passwd\@host:port/
  user :: Ptr CChar,
  -- password, as in http://user:passwd\@host:port/
  password :: Ptr CChar,
  -- hostname from URI (or from Host: header)
  hostname :: Ptr CChar,
  -- the request path (or NULL if only scheme://host was given)
  path :: Ptr CChar,
  -- Everything after a '?' in the path, if present
  query :: Ptr CChar,
  -- Trailing "#fragment" string, if present
  fragment :: Ptr CChar,
  -- The port number, numeric, valid only if port_str != NULL
  port :: Maybe #type apr_port_t
}

instance Storable Uri where
  sizeOf _ = (#size apr_uri_t)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    scheme <- (#peek apr_uri_t, scheme) ptr
    hostinfo <- (#peek apr_uri_t, hostinfo) ptr
    user <- (#peek apr_uri_t, user) ptr
    password <- (#peek apr_uri_t, password) ptr
    hostname <- (#peek apr_uri_t, hostname) ptr
    path <- (#peek apr_uri_t, path) ptr
    query <- (#peek apr_uri_t, query) ptr
    fragment <- (#peek apr_uri_t, fragment) ptr
    portStr <- (#peek apr_uri_t, port_str) ptr
    port <- if nullPtr /= portStr
            then fmap Just $ (#peek apr_uri_t, scheme) ptr
            else return Nothing
    return $ Uri scheme hostinfo user password hostname path query fragment port
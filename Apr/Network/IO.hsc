{-# LANGUAGE ForeignFunctionInterface, ScopedTypeVariables #-}

module Apr.Network.IO (
  SockAddr(..),
  SockAddrIn(..),
  InAddr(..)
  ) where 

import Data.Int
import Data.Word
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable

#include <apr-1.0/apr_network_io.h>
#include <netinet/in.h>

data SockAddr = SockAddr {
  -- The numeric port
  port :: #{type apr_port_t},
  -- Union of either IPv4 or IPv6 sockaddr.
  sin :: SockAddrIn
}

-- TODO: move into a module for /usr/include/netinet/in.h ?

data SockAddrIn = SockAddrInInet {
  sinAddr :: InAddr
  } | SockAddrInInet6

data InAddr = InAddr {
  sAddr :: #{type in_addr_t}
  }

instance Storable SockAddr where
  sizeOf _ = (#size apr_sockaddr_t)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    port <- (#peek apr_sockaddr_t, port) ptr
    family :: #{type apr_int32_t} <- (#peek apr_sockaddr_t, family) ptr
    sin <- case family of
      (#const AF_INET) -> fmap SockAddrInInet $ (#peek apr_sockaddr_t, sa.sin) ptr
      k -> error $ "only support AF_INET right now, not " ++ (show k)
    return $ SockAddr port sin
    
instance Storable InAddr where
  sizeOf _ = (#size struct sockaddr_in)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    sAddr <- (#peek struct sockaddr_in, sin_addr.s_addr) ptr
    return $ InAddr sAddr
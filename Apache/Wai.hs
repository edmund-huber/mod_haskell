{-# LANGUAGE ForeignFunctionInterface #-}

module Apache.Wai where

import Data.Word
import Foreign.C.String
import Foreign.C.Types
import Foreign.Marshal.Array
import Foreign.Ptr
import System.IO.Unsafe

data WaiConsumer = WaiConsumer 

wai_adapter :: Ptr Word8 -> CInt -> CString -> CInt -> CInt -> IO (FunPtr WaiConsumer)
wai_adapter
  c_buffer c_buffer_sz
  c_method c_http_major c_http_minor =
  do
    -- fill up c_buffer, with up to c_buffer_sz bytes
    -- if we're done, return a null function pointer
    -- otherwise, return a recursive function pointer
    
foreign export ccall wai_adapter :: Ptr Word8 -> CInt -> CString -> CInt -> CInt -> IO (FunPtr WaiConsumer)

  --let
  --  method = unsafePerformIO $ peekCString c_method
  --  ret = "method is: " ++ method ++ ", http " ++ (show c_http_major) ++ "." ++ (show c_http_minor)
  --in
  --  unsafePerformIO $ pokeArray ret 
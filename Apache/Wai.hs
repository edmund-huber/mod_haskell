{-# LANGUAGE ForeignFunctionInterface #-}

module Apache.Wai where

import Foreign.C.Types

hs_add_3 :: CInt -> CInt
hs_add_3 i = 3 + fromIntegral i

foreign export ccall hs_add_3 :: CInt -> CInt
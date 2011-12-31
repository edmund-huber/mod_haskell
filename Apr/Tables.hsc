{-# LANGUAGE ForeignFunctionInterface #-}

module Apr.Tables where

import Data.Word
import Foreign.C.String
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable

#include <apr-1.0/apr_tables.h>

data Header = Header {
  -- The amount of memory allocated for each element of the array
  eltSize :: CInt,
  -- The number of active elements in the array
  nElts :: CInt,
  -- The number of elements allocated in the array
  nAlloc :: CInt,
  -- The elements in the array
  elts :: Ptr Entry
}

data Entry = Entry {
  -- The key for the current table entry (maybe NULL)
  key :: Ptr CChar,
  -- The value for the current table entry
  val :: Ptr CChar
}

instance Storable Header where
  sizeOf _ = (#size apr_array_header_t)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    eltSize <- (#peek apr_array_header_t, elt_size) ptr
    nElts <- (#peek apr_array_header_t, nelts) ptr
    nAlloc <- (#peek apr_array_header_t, nalloc) ptr
    elts <- (#peek apr_array_header_t, elts) ptr
    return $ Header eltSize nElts nAlloc elts
  poke ptr (Header a b c d) = do
    (#poke apr_array_header_t, elt_size) ptr a
    (#poke apr_array_header_t, nelts) ptr b
    (#poke apr_array_header_t, nalloc) ptr c
    (#poke apr_array_header_t, elts) ptr d

instance Storable Entry where
  sizeOf _ = (#size apr_table_entry_t)
  alignment _ = alignment (undefined :: CInt)
  peek ptr = do
    key <- (#peek apr_table_entry_t, key) ptr
    val <- (#peek apr_table_entry_t, val) ptr
    return $ Entry key val
  poke ptr (Entry a b) = do
    (#poke apr_table_entry_t, key) ptr a
    (#poke apr_table_entry_t, val) ptr b

fromAprTable :: Ptr Header -> IO [([Char], [Char])]
fromAprTable ptr =
  do
    Header {nElts=nElts, elts=ptrElts} <- peek ptr
    let nElems = fromIntegral nElts
    let
      makeList :: Int -> IO [([Char], [Char])]
      makeList 0 = do return []
      makeList n = do
          Entry {key=k, val=v} <- peekElemOff ptrElts $ nElems - n
          kString <- peekCString k
          vString <- peekCString v
          kvs <- makeList $ n - 1
          return $ (kString, vString):kvs
    makeList nElems
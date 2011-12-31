What is mod_haskell?
--------------------

A mod_so -style Apache module for building web applications in
Haskell.

Implements these interfaces to Haskell code:
  * WAI
    * http://www.haskell.org/haskellwiki/WebApplicationInterface
    * http://hackage.haskell.org/packages/archive/wai/latest/doc/html/Network-Wai.html

How do I use it?
----------------

Import your application in Apache/Glue.hs , and set the 'app' variable
to your instance. Then, run make && sudo make install .




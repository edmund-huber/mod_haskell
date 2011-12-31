GHC_LIBS=$(shell ghc --print-libdir)
GHC_OPTS=-Wall -dynamic -fPIC

# Only certain suffixes.
.SUFFIXES:
.SUFFIXES: .hi .hs .hsc

mod_haskell: mod_haskell.c Apache/Glue.hs Apache/Request.hi Apr/Tables.hi Apr/Uri.hi Dummy.hi
	# Just for the sake of generating the stub.h
	ghc -c $(GHC_OPTS) Apache/Glue.hs -XForeignFunctionInterface
	# Link against the apache runtime!
	gcc -c -I/usr/include/apache2 -I/usr/include/apr-1.0 -I$(GHC_LIBS)/include -IApache/ -fPIC -Wall mod_haskell.c -lapr-1 -o mod_haskell.o
	# * Allow GHC to build the shared library because ??? it is supposedly good for you
	# * Include '-lm -lrt' because the GHC runtime expects them to be there
	ghc $(GHC_OPTS) -shared Apache/Glue.hs mod_haskell.o -lm -lrt -lffi -L$(GHC_LIBS) -lHSrts -o mod_haskell.so

.hs.hs:
	ghc -c $(GHC_OPTS) $<

.hsc.hs:
	hsc2hs --cc=gcc --cflag="-fPIC $$(apr-config --cppflags --cflags) -I$(GHC_LIBS)/include -I/usr/include/apr-1.0" $<

install: mod_haskell
	cp mod_haskell.so /usr/lib/apache2/modules
	echo "LoadModule haskell_module /usr/lib/apache2/modules/mod_haskell.so" > /etc/apache2/mods-available/haskell.load
	echo "<Location /docroot>\nSetHandler haskell\n</Location>" > /etc/apache2/httpd.conf
	/etc/init.d/apache2 restart
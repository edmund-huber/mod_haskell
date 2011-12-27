GHC_LIBS=$(shell ghc --print-libdir)
GHC_OPTS=-Wall -fforce-recomp -dynamic

mod_wai: mod_wai.c Apache/Wai.hs Apr/Tables.hi Dummy.hi
	# Just for the sake of generating the stub.h
	ghc -c $(GHC_OPTS) Apache/Wai.hs -XForeignFunctionInterface
	# Link against the apache runtime!
	gcc -c -I/usr/include/apache2 -I/usr/include/apr-1.0 -I$(GHC_LIBS)/include -IApache/ -Wall mod_wai.c -lapr-1 -o mod_wai.o
	# * Allow GHC to build the shared library because ??? it is supposedly good for you
	# * Include '-lm -lrt' because the GHC runtime expects them to be there
	ghc $(GHC_OPTS) -shared -dynamic -fPIC Apache/Wai.hs mod_wai.o -lm -lrt -lffi -L$(GHC_LIBS) -lHSrts -o mod_wai.so

Dummy.hi: Dummy.hs
	ghc -c $(GHC_OPTS) Dummy.hs

Apr/Tables.hi: Apr/Tables.hs
	ghc -c $(GHC_OPTS) Apr/Tables.hs

Apr/Tables.hs: Apr/Tables.hsc
	hsc2hs --cc=gcc --cflag="$$(apr-config --cppflags --cflags) -I$(GHC_LIBS)/include" Apr/Tables.hsc

install: mod_wai
	cp mod_wai.so /usr/lib/apache2/modules
	echo "LoadModule wai_module /usr/lib/apache2/modules/mod_wai.so" > /etc/apache2/mods-available/wai.load
	echo "<Location /docroot>\nSetHandler wai\n</Location>" > /etc/apache2/httpd.conf
	/etc/init.d/apache2 restart
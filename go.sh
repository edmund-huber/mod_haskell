#!/bin/bash

echo -e "<Location /docroot>\nSetHandler wai\n</Location>" | sudo tee /etc/apache2/httpd.conf && sudo apxs2 -i -a -c mod_wai.c && sudo /etc/init.d/apache2 restart
# dont judge
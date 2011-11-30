#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "ap_config.h"

static int wai_handler(request_rec *r) {
  /* just always handle, because r->handler for some reason is being
     set to "text/html" -- probably some version mismatch that I don't
     want to spend my evening tracking down
  */
  if (!r->header_only) {
    ap_rputs("haskell here\n", r);
  }
  return OK;
}

static void wai_register_hooks(apr_pool_t *p) {
  ap_hook_handler(wai_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

/* Dispatch list for API hooks */
module AP_MODULE_DECLARE_DATA wai_module = {
  STANDARD20_MODULE_STUFF, 
  NULL,                  /* create per-dir    config structures */
  NULL,                  /* merge  per-dir    config structures */
  NULL,                  /* create per-server config structures */
  NULL,                  /* merge  per-server config structures */
  NULL,                  /* table of config file commands       */
  wai_register_hooks  /* register hooks                      */
};


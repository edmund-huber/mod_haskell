#include <httpd.h>
#include <http_config.h>
#include <http_protocol.h>
#include <ap_config.h>
#include <HsFFI.h>

#include <Wai_stub.h>

extern void __stginit_ApacheziWai(void);

__attribute__((constructor)) void init(void) {
  // initialize the Haskell runtime library
  int argc = 1;
  char *name = "mod_wai";
  char **argv = &name;
  hs_init(&argc, &argv);
  hs_add_root(__stginit_ApacheziWai);
}


static int wai_handler(request_rec *r) {
  if (!r->header_only) {
    char buf[4096];
    // (need to run this until WAI sez: "NO MORE!")
    wai_adapter(buf, sizeof(buf), r->method, 1, 2);
    ap_rputsn(buf, n, r);
  }
  return OK;
}

static void wai_register_hooks(apr_pool_t *p) {
  ap_hook_handler(wai_handler, NULL, NULL, APR_HOOK_MIDDLE);  
}

module AP_MODULE_DECLARE_DATA wai_module = {
  STANDARD20_MODULE_STUFF, 
  NULL,                  /* create per-dir    config structures */
  NULL,                  /* merge  per-dir    config structures */
  NULL,                  /* create per-server config structures */
  NULL,                  /* merge  per-server config structures */
  NULL,                  /* table of config file commands */
  wai_register_hooks
};

#include <httpd.h>
#include <http_config.h>
#include <http_protocol.h>
#include <ap_config.h>
#include <HsFFI.h>

#include <Glue_stub.h>

extern void __stginit_ApacheziGlue(void);

// so it's not clear when I can deallocate the content_type .. so I
// guess I won't

typedef struct {
  char *content_type;
  void *next;
} content_type_list_t;

content_type_list_t *content_type_list = NULL;

void set_content_type(request_rec *r, char *content_type) {
  content_type_list_t **p = &content_type_list;
  while(NULL != *p) {
    if(0 == strcmp((*p)->content_type, content_type)) {
      r->content_type = (*p)->content_type;
      return;
    } else {
      p = (content_type_list_t **)&((*p)->next);
    }
  }
  *p = malloc(sizeof(content_type_list_t));
  r->content_type = (*p)->content_type = strdup(content_type);
}

__attribute__((constructor)) void init(void) {
  // initialize the Haskell runtime library
  int argc = 1;
  char *name = "mod_haskell";
  char **argv = &name;
  hs_init(&argc, &argv);
  hs_add_root(__stginit_ApacheziGlue);
}

static int haskell_handler(request_rec *r) {
  feedApacheRequestToApplication(r);
  return OK;
}

static void haskell_register_hooks(apr_pool_t *p) {
  ap_hook_handler(haskell_handler, NULL, NULL, APR_HOOK_MIDDLE);  
}

module AP_MODULE_DECLARE_DATA haskell_module = {
  STANDARD20_MODULE_STUFF, 
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  haskell_register_hooks
};

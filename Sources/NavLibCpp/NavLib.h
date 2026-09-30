#include "navlib_base.h"
#include "navlib_error.h"
#include "siappcmd_types.h"
#include <stdbool.h>

bool NavLibIsAvailable(void);

long NlCreate(navlib::nlHandle_t *pnh,
              const char *appname,
              const navlib::accessor_t property_accessors[],
              size_t accessor_count,
              const navlib::nlCreateOptions_t *options);

long NlClose(navlib::nlHandle_t nh);
long NlReadValue(navlib::nlHandle_t nh, navlib::property_t name, navlib::value_t *value);
long NlWriteValue(navlib::nlHandle_t nh, navlib::property_t name, const navlib::value_t *value);

// One node of a command tree, as passed to NlWriteCommandTree. `parent` is the index of the parent
// node in the same array, or -1 for the root.
typedef struct {
    SiActionNodeType_t type;
    const char *id;
    const char *label;
    const char *description;
    long parent;
} NlCommandNode;

// Builds a command tree from `nodes` and writes it to the navlib `commands.tree` property, then makes
// it the active set via `commands.activeSet`. `nodes[0]` must be the SI_ACTIONSET_NODE root, and every
// node must come after its parent; siblings keep their relative order. The actions become assignable to
// device buttons in the 3Dconnexion configuration UI. The navlib copies the strings during the call, so
// the caller's buffers only need to remain valid for the duration of this function.
long NlWriteCommandTree(navlib::nlHandle_t nh, const NlCommandNode *nodes, size_t count);

#include "navlib_base.h"
#include "navlib_error.h"
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

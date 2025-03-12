#include "navlib_base.h"
#include "NavLib.h"

bool NavLibIsAvailable(void) {
    return navlib::NlCreate != NULL;
}

long NlCreate(navlib::nlHandle_t *pnh, const char *appname, const navlib::accessor_t property_accessors[], size_t accessor_count, const navlib::nlCreateOptions_t *options) __attribute__((weak_import)) {
    return navlib::NlCreate(pnh, appname, property_accessors, accessor_count, options);
}

long NlClose(navlib::nlHandle_t nh) {
    return navlib::NlClose(nh);
}

long NlReadValue(navlib::nlHandle_t nh, navlib::property_t name, navlib::value_t *value) {
    return navlib::NlReadValue(nh, name, value);
}

long NlWriteValue(navlib::nlHandle_t nh, navlib::property_t name, const navlib::value_t *value) {
    return navlib::NlWriteValue(nh, name, value);
}

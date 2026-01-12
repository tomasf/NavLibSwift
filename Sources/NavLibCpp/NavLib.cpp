#include "navlib_base.h"
#include "NavLib.h"
#include <dlfcn.h>

// Framework path
static const char* kFrameworkPath = "/Library/Frameworks/3DconnexionNavlib.framework/3DconnexionNavlib";

// Function pointer types matching the navlib API
typedef long (*NlCreateFn)(navlib::nlHandle_t*, const char*, const navlib::accessor_t[], size_t, const navlib::nlCreateOptions_t*);
typedef long (*NlCloseFn)(navlib::nlHandle_t);
typedef long (*NlReadValueFn)(navlib::nlHandle_t, navlib::property_t, navlib::value_t*);
typedef long (*NlWriteValueFn)(navlib::nlHandle_t, navlib::property_t, const navlib::value_t*);

// Loaded function pointers
static NlCreateFn g_NlCreate = nullptr;
static NlCloseFn g_NlClose = nullptr;
static NlReadValueFn g_NlReadValue = nullptr;
static NlWriteValueFn g_NlWriteValue = nullptr;

// Handle to the loaded framework
static void* g_frameworkHandle = nullptr;
static bool g_initialized = false;

static void initializeNavLib() {
    if (g_initialized) return;
    g_initialized = true;

    g_frameworkHandle = dlopen(kFrameworkPath, RTLD_LAZY);
    if (!g_frameworkHandle) {
        return;
    }

    // Load function pointers (extern "C" functions, so no name mangling)
    g_NlCreate = (NlCreateFn)dlsym(g_frameworkHandle, "NlCreate");
    g_NlClose = (NlCloseFn)dlsym(g_frameworkHandle, "NlClose");
    g_NlReadValue = (NlReadValueFn)dlsym(g_frameworkHandle, "NlReadValue");
    g_NlWriteValue = (NlWriteValueFn)dlsym(g_frameworkHandle, "NlWriteValue");

    // If any function failed to load, treat as unavailable
    if (!g_NlCreate || !g_NlClose || !g_NlReadValue || !g_NlWriteValue) {
        dlclose(g_frameworkHandle);
        g_frameworkHandle = nullptr;
        g_NlCreate = nullptr;
        g_NlClose = nullptr;
        g_NlReadValue = nullptr;
        g_NlWriteValue = nullptr;
    }
}

bool NavLibIsAvailable(void) {
    initializeNavLib();
    return g_frameworkHandle != nullptr;
}

long NlCreate(navlib::nlHandle_t *pnh, const char *appname, const navlib::accessor_t property_accessors[], size_t accessor_count, const navlib::nlCreateOptions_t *options) {
    initializeNavLib();
    if (!g_NlCreate) {
        return navlib::make_result_code(navlib::navlib_errc::function_not_supported);
    }
    return g_NlCreate(pnh, appname, property_accessors, accessor_count, options);
}

long NlClose(navlib::nlHandle_t nh) {
    if (!g_NlClose) {
        return navlib::make_result_code(navlib::navlib_errc::function_not_supported);
    }
    return g_NlClose(nh);
}

long NlReadValue(navlib::nlHandle_t nh, navlib::property_t name, navlib::value_t *value) {
    if (!g_NlReadValue) {
        return navlib::make_result_code(navlib::navlib_errc::function_not_supported);
    }
    return g_NlReadValue(nh, name, value);
}

long NlWriteValue(navlib::nlHandle_t nh, navlib::property_t name, const navlib::value_t *value) {
    if (!g_NlWriteValue) {
        return navlib::make_result_code(navlib::navlib_errc::function_not_supported);
    }
    return g_NlWriteValue(nh, name, value);
}

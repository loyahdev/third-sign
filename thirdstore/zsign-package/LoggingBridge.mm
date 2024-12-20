// LoggingBridge.mm
#include "LoggingBridge.h"

static void (*swiftLogCallback)(const char *) = nullptr;

void registerSwiftLogCallback(void (*callback)(const char *)) {
    swiftLogCallback = callback;
}

void logFromCpp(const char *message) {
    if (swiftLogCallback != nullptr) {
        swiftLogCallback(message);
    }
}

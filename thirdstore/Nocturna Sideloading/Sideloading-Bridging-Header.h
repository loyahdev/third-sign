// Sideloading-Bridging-Header.h
void registerSwiftLogCallback(void (*callback)(const char *));
void logFromCpp(const char *message);

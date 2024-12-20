// LoggingBridge.h
#ifdef __cplusplus
extern "C" {
#endif

void registerSwiftLogCallback(void (*callback)(const char *));
void logFromCpp(const char *message);

#ifdef __cplusplus
}
#endif

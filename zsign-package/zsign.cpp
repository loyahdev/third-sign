#include "common/common.h"
#include "bundle.h"

extern "C" int zsign(char* appPath, char* p12Path, char* provPath, char* pass, char* bundleID, char* bundleVersion, char* displayName, char* tweakDylib);

int zsign(char* appPath, char* p12Path, char* provPath, char* pass, char* bundleID, char* bundleVersion, char* displayName, char* tweakDylib) {    
	ZLog::PrintV("Testing... appPath: \t%s\n", appPath);
    if (!IsFileExists(appPath)) {
        ZLog::ErrorV("Invalid Path! %s\n", appPath);
        return -1;
    }
    ZSignAsset zSignAsset;
    if (!zSignAsset.Init("", p12Path, provPath, "", pass)) {
        return -1;
    }
    ZAppBundle bundle;
    bool bRet = bundle.SignFolder(&zSignAsset, appPath, bundleID, bundleVersion, displayName, tweakDylib, true, true, true);
    return bRet ? 0 : -1;
}

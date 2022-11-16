#ifndef CRUALFRPCINFO_H
#define CRUALFRPCINFO_H

#include <string>
#include "Alfred/rpcinfo.h"
#include "Alfred/service.h"
#include "Fred/fred.h"
#include "Alfred/types.h"

using namespace std;

class CruAlfRpcInfo: public RpcInfoString
{
public:
    CruAlfRpcInfo(string name, Fred* fred, ALFRED_TYPES::CRU_TYPES type);
    void setResponseService(ServiceString* responseService);

    const string& getName();

private:
    const void* Execution(void* value);
    ALFRED_TYPES::CRU_TYPES type;
    ServiceString* responseService;
};

#endif // CRUALFRPCINFO_H

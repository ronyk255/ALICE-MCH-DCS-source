#ifndef LLAALFRPCINFO_H
#define LLAALFRPCINFO_H

#include <string>
#include "Alfred/rpcinfo.h"
#include "Fred/fred.h"
#include "Alfred/types.h"

using namespace std;

class LlaAlfRpcInfo: public RpcInfoString
{
public:
    LlaAlfRpcInfo(string name, Fred* fred, ALFRED_TYPES::LLA_TYPES type);
    bool requestLlaSession(bool printError = false);

    const string& getName();

private:
    const void* Execution(void* value);
    ALFRED_TYPES::LLA_TYPES type;
};

#endif

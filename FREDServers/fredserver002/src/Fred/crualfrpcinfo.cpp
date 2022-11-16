#include "Fred/crualfrpcinfo.h"
#include "Alfred/print.h"

CruAlfRpcInfo::CruAlfRpcInfo(string name, Fred* fred, ALFRED_TYPES::CRU_TYPES type): RpcInfoString::RpcInfoString(name, " ", (ALFRED*)fred)
{
    this->type = type;
    this->responseService = NULL;
}

void CruAlfRpcInfo::setResponseService(ServiceString* responseService)
{
    this->responseService = responseService;
}

const void* CruAlfRpcInfo::Execution(void *value) //todo
{
    if (!value)
    {
        Print::PrintError(this->name, "Invalid RPC Info received!");
        return NULL;
    }

    string response(static_cast<char*>(value));

    Print::PrintVerbose(this->name, "Received RPC Info:\n" + response);

    // not supported
    /*if (this->type == ALFRED_TYPES::CRU_TYPES::READ && (response.find("success") != string::npos || response.find("failure") != string::npos))
    {
        response.erase(0, response.find("\n") + 1);
    }*/

    if (response.size() && response[response.size() - 1] == '\n')
    {
        response = response.substr(0, response.size() - 1);
    }

    if (this->responseService)
    {
        this->responseService->Update(response);
        this->setResponseService(NULL);
    }
    else
    {
        Print::PrintError(this->name, "No response service available!");
    }


    return NULL;
}

const string& CruAlfRpcInfo::getName()
{
    return this->name;
}

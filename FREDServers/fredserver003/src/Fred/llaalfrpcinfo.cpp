#include "Fred/llaalfrpcinfo.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"

LlaAlfRpcInfo::LlaAlfRpcInfo(string name, Fred* fred, ALFRED_TYPES::LLA_TYPES type): RpcInfoString::RpcInfoString(name, " ", (ALFRED*)fred)
{
    this->type = type;
}

const void* LlaAlfRpcInfo::Execution(void* value)
{
    return value;
}

bool LlaAlfRpcInfo::requestLlaSession(bool printError)
{
    char* request = strdup(this->type == ALFRED_TYPES::LLA_TYPES::START ? this->Parent()->Name().c_str() : "");
    void* value = this->Send(request);
    free(request);

    if (!value)
    {
        Print::PrintError(this->name, "Invalid LLA RPC Info received!");
        return false;
    }

    string response(static_cast<char*>(value));

    Print::PrintVerbose(this->name, "LLA RPC response: " + response);

    bool executionCorrect = response.find(ProcessMessage::SUCCESS) != string::npos;
    if (executionCorrect)
    {
        Print::PrintVerbose(this->type == ALFRED_TYPES::LLA_TYPES::START ? "LLA Session started!" : "LLA Session stopped!");
        return true;
    }

    if (printError)
    {
        Print::PrintError(this->type == ALFRED_TYPES::LLA_TYPES::START ? "Cannot start LLA Session!" : "Cannot stop LLA Session!");
    }
    return false;
}

const string& LlaAlfRpcInfo::getName()
{
    return this->name;
}

#ifndef ALFRPCINFO_H
#define ALFRPCINFO_H

#include <string>
#include "Alfred/rpcinfo.h"
#include "Fred/fred.h"
#include "Fred/Config/location.h"

using namespace std;

class AlfRpcInfo: public RpcInfoString
{
private:
    pair<ProcessMessage*, ChainTopic*> currentTransaction;

    const void* Execution(void* value);
    void clearTransaction();
    bool isTransactionAvailable();
    string name;
    Location::AlfEntry::Version version;

    string fullResponse;
    size_t currentPart, pollRepeat;

public:
    AlfRpcInfo(string name, string dns, Fred* fred, Location::AlfEntry::Version version);
    void setTransaction(pair<ProcessMessage*, ChainTopic*> currentTransaction);
    const string& getName();
    Location::AlfEntry::Version getVersion();
};

#endif // ALFRPCINFO_H

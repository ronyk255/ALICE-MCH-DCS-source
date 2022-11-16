#ifndef CRUREGISTERCOMMAND_H
#define CRUREGISTERCOMMAND_H

#include <string>
#include "Alfred/command.h"
#include "Alfred/service.h"
#include "Fred/crualfrpcinfo.h"
#include <thread>
#include <condition_variable>
#include <mutex>
#include <atomic>
#include <list>
#include <algorithm>
#include "Alfred/types.h"

class Fred;
class RpcInfoString;

class CruRegisterCommand: public CommandString
{
public:
    CruRegisterCommand(ALFRED_TYPES::CRU_TYPES type, string topicName, CruAlfRpcInfo* rpcInfo, Fred* fred);
    ~CruRegisterCommand();

private:
    ALFRED_TYPES::CRU_TYPES type;
    string name;
    ServiceString* responseService;
    CruAlfRpcInfo* rpcInfo;

    const void* Execution(void* value);

    //void executeWrite(vector<string>& message);
    //void executeRead(vector<string>& message);
    void executePatternPlayer(vector<string>& message);

    condition_variable conditionVar;
    thread* clearThread;
    atomic<bool> isFinished, isProcessing;
    list<pair<string, RpcInfoString*> > stack;
    mutex stackMutex;

    static void clearRequests(CruRegisterCommand* self);
    void newRequest(pair<string, RpcInfoString*> request);

    static string getTypeReqName(ALFRED_TYPES::CRU_TYPES type, string topicName, const string& suffix);
};

#endif // CRUREGISTERCOMMAND_H

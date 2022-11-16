#include "Fred/cruregistercommand.h"
#include "Alfred/print.h"
#include "Fred/fred.h"
#include "Parser/utility.h"
#include "Fred/crualfrpcinfo.h"
#include <sstream>
#include <iomanip>
#include <exception>

CruRegisterCommand::CruRegisterCommand(ALFRED_TYPES::CRU_TYPES type, string topicName, CruAlfRpcInfo* rpcInfo, Fred* fred): CommandString::CommandString(fred->Name() + CruRegisterCommand::getTypeReqName(type, topicName, "REQ"), (ALFRED*)fred)
{
    this->type = type;
    this->rpcInfo = rpcInfo;
    this->name = fred->Name() + CruRegisterCommand::getTypeReqName(type, topicName, "REQ");
    this->responseService = new ServiceString(fred->Name() + CruRegisterCommand::getTypeReqName(type, topicName, "ANS"), (ALFRED*)fred);
    fred->RegisterService(this->responseService);

    this->isFinished = false;
    this->isProcessing = false;
    this->clearThread = new thread(clearRequests, this);
}

CruRegisterCommand::~CruRegisterCommand()
{
    this->isFinished = true;
    conditionVar.notify_one();
    clearThread->join();
    delete clearThread;
}

const void* CruRegisterCommand::Execution(void *value)
{
    if (!value)
    {
        Print::PrintError(name, "Invalid request, no value received!");
    }

    string request(static_cast<char*>(value));

    Print::PrintVerbose(name, "Received command:\n" + request);

    vector<string> splitted = Utility::splitString(request, ",");

    // not supported
    /*if (this->type == ALFRED_TYPES::CRU_TYPES::WRITE)
    {
        if (splitted.size() != 2)
        {
            Print::PrintError(name, "Invalid number of arguments received for CRU_REGISTER WRITE");
            return NULL;
        }

        executeWrite(splitted);
    }
    else if (this->type == ALFRED_TYPES::CRU_TYPES::READ)
    {
        if (splitted.size() != 1)
        {
            Print::PrintError(name, "Invalid number of arguments received for CRU_REGISTER READ");
            return NULL;
        }

        executeRead(splitted);
    }
    else */if (this->type == ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER)
    {
        if (splitted.size() != 11)
        {
            Print::PrintError(name, "Invalid number of arguments received for PATTERN PLAYER");
            return NULL;
        }

        executePatternPlayer(splitted);
    }

    return NULL;
}

// not supported
/*void CruRegisterCommand::executeWrite(vector<string>& message) // 0 - ADDR, 1 - VALUE
{
    stringstream request;

    try
    {
        uint32_t address = Utility::stringToNumber(message[0]);
        uint32_t value = Utility::stringToNumber(message[1]);

        request << "0x" << hex << address << "," << "0x" << hex << value;
    }
    catch (invalid_argument& e)
    {
        Print::PrintError(name, "Invalid request received!");
        return;
    }

    newRequest(make_pair(request.str(), rpcInfo));
}

void CruRegisterCommand::executeRead(vector<string>& message) // 0 - ADDR
{
    stringstream request;

    try
    {
        uint32_t address = Utility::stringToNumber(message[0]);

        request << "0x" << hex << address;
    }
    catch (invalid_argument& e)
    {
        Print::PrintError(name, "Invalid request received!");
        return;
    }

    newRequest(make_pair(request.str(), rpcInfo));
}*/

void CruRegisterCommand::executePatternPlayer(vector<string>& message) // 0 - SYNC_P, 1 - RESET_P, 2 - IDLE_P, 3 - SYNC_L, 4 - SYNC_D, 5 - RESET_L, 6 - RESET_TS, 7 - SYNC_TS, 8 - SYNC_S, 9 - TRIG_S, 10 - TRIG_R
{
    stringstream request;

    try
    {
        uint128_t syncPattern = Utility::stringToLargeNumber(message[0]);
        uint128_t resetPattern = Utility::stringToLargeNumber(message[1]);
        uint128_t idlePattern = Utility::stringToLargeNumber(message[2]);
        uint32_t syncLength = Utility::stringToNumber(message[3]);
        uint32_t syncDelay = Utility::stringToNumber(message[4]);
        uint32_t resetLength = Utility::stringToNumber(message[5]);
        uint32_t resetTriggerSelect = Utility::stringToNumber(message[6]);
        uint32_t syncTriggerSelect = Utility::stringToNumber(message[7]);
        bool syncAtStart = message[8] == "true";
        bool triggerSync = message[9] == "true";
        bool triggerReset = message[10] == "true";

        request << Utility::largeNumberToHexString(syncPattern) << "\n" << Utility::largeNumberToHexString(resetPattern) << "\n" << Utility::largeNumberToHexString(idlePattern)
                << "\n" << to_string(syncLength) << "\n" << to_string(syncDelay) << "\n" << to_string(resetLength) << "\n" << to_string(resetTriggerSelect) << "\n" << to_string(syncTriggerSelect)
                << "\n" << (syncAtStart ? "true" : "false") << "\n" << (triggerSync ? "true" : "false") << "\n" << (triggerReset ? "true" : "false");
    }
    catch (invalid_argument& e)
    {
        Print::PrintError(name, "Invalid request received!");
        return;
    }

    newRequest(make_pair(request.str(), rpcInfo));
}

void CruRegisterCommand::clearRequests(CruRegisterCommand *self)
{
    mutex lock;
    unique_lock<mutex> uniqueLock(lock);

    while (1)
    {
        if (self->isFinished)
        {
            return;
        }

        self->conditionVar.wait(uniqueLock);

        while (!self->stack.empty())
        {
            self->isProcessing = true;

            pair<string, RpcInfoString*> request;
            {
                lock_guard<mutex> lockGuard(self->stackMutex);
                request = self->stack.front();
                self->stack.pop_front();
            }
            //do processing

            Print::PrintVerbose(self->name, "Sending request to " + request.second->Name() + "\n" + request.first);
            char* buffer = strdup(request.first.c_str());
            dynamic_cast<CruAlfRpcInfo*>(request.second)->setResponseService(self->responseService);
            request.second->Send(buffer);
            free(buffer);

            self->isProcessing = false;
        }
    }
}

void CruRegisterCommand::newRequest(pair<string, RpcInfoString*> request)
{
    {
        lock_guard<mutex> lockGuard(stackMutex);
        stack.push_back(request);
    }

    if (!isProcessing)
    {
        conditionVar.notify_one();
    }
}

string CruRegisterCommand::getTypeReqName(ALFRED_TYPES::CRU_TYPES type, string topicName, const string& suffix)
{
    switch (type)
    {
    //case ALFRED_TYPES::CRU_TYPES::READ:
    //    return "/" + topicName + "/REGISTER_READ_" + suffix;
    //case ALFRED_TYPES::CRU_TYPES::WRITE:
    //    return "/" + topicName + "/REGISTER_WRITE_" + suffix;
    case ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER:
        return "/" + topicName + "/PATTERN_PLAYER_" + suffix;
    }
}

#ifndef LLALOCK_H
#define LLALOCK_H

#include <string>
#include <vector>
#include "Fred/queue.h"
#include "Fred/fred.h"
#include "Fred/llaalfrpcinfo.h"
#include <atomic>
#include <mutex>

using namespace std;

class LlaLock
{
public:
    LlaLock(const string& alf, int32_t serial, uint32_t repeat, uint32_t delay, vector<Queue*> queues, Fred* fred);
    bool startLlaSession();
    bool stopLlaSession();
    bool overrideLlaSession(bool enable);

private:
    uint32_t repeat, delay;
    vector<Queue*> queues;
    Fred* fred;

    LlaAlfRpcInfo *startLla, *stopLla;
    atomic<bool> hasLlaSession, overridenSession;

    mutex sessionAccesss;

    bool checkQueuesEmpty();
};

#endif

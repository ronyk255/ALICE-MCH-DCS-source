#ifndef INDEFINITEMAPI_H
#define INDEFINITEMAPI_H

#include "Fred/Mapi/mapi.h"
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <map>
#include <utility>

using namespace std;

class IndefiniteMapi: public Mapi
{
private:
    thread* executionThread;
    thread::id executionThreadId;
    atomic<bool> isFinished;

    condition_variable requestRecv, sequenceRecv;
    string response;
    pair<string, bool> request;
    mutex requestAccess, sequenceAccess;

    static map<thread::id, IndefiniteMapi*> mappedThreads;

    void doExecution();

public:
    IndefiniteMapi();
    virtual ~IndefiniteMapi();

    void registerMapi(Fred* fred, string name);

    string processInputMessage(string input) final;
    string processOutputMessage(string output) final;

    virtual void processExecution() = 0;

    string waitForRequest(bool& running);
    bool isRequestAvailable(bool& running);
    string getRequest();

    string executeAlfSequence(string sequence);

    bool customMessageProcess();
    void requestReceived(string request);

    static IndefiniteMapi* getCurrentMapi();
};

#endif

#ifndef QUEUE_H
#define QUEUE_H

#include <thread>
#include <list>
#include <utility>
#include <condition_variable>
#include <mutex>
#include <atomic>
#include <string>
#include "Fred/fredtopics.h"
#include "Parser/processmessage.h"

using namespace std;

class Fred;
class LlaLock;

class Queue
{
public:
    Queue(Fred* fred, string name);
    ~Queue();

    void newRequest(pair<ProcessMessage *, ChainTopic *> request);

    size_t getStackSize();
    void setLlaLock(LlaLock* llaLock);
    LlaLock* getLlaLock();
    bool processing();

private:
    Fred* fred;
    condition_variable conditionVar;
    thread* queueThread;
    atomic<bool> isFinished, isProcessing;
    list<pair<ProcessMessage *, ChainTopic*> > stack;
    mutex stackMutex;
    LlaLock* llaLock;
    string name;

    static void clearQueue(Queue* queue);
    bool checkLlaStartSession();
    void checkLlaStopSession();
};

#endif // QUEUE_H

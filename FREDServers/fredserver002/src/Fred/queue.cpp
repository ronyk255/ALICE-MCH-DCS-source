#include <ctime>
#include <chrono>
#include <iomanip>
#include "Fred/queue.h"
#include "Fred/alfrpcinfo.h"
#include "Fred/alfinfo.h"
#include "Alfred/print.h"
#include "Fred/llalock.h"

Queue::Queue(Fred* fred, string n)
{
    this->fred = fred;
    this->isFinished = false;
    this->isProcessing = false;
    this->llaLock = NULL;
    this->name = n;
    this->queueThread = new thread(clearQueue, this);
}

Queue::~Queue()
{
    unique_lock<mutex> uniqueLock(this->stackMutex);
    this->isFinished = true;
    uniqueLock.unlock();
    conditionVar.notify_one();
    queueThread->join();
    delete queueThread;
}

void Queue::clearQueue(Queue *queue)
{
  while (1)
  {
    unique_lock<mutex> uniqueLock(queue->stackMutex);
   // Print::PrintError(queue->name, " clearQueue locked");

    if (queue->isFinished)
    {
      return;
    }

    if (queue->stack.empty() && queue->isProcessing)
    {
       // Print::PrintError(" checkLlaStopSession before\n");
        queue->isProcessing = false;
        uniqueLock.unlock();
        auto tStart = std::chrono::steady_clock::now();
        queue->checkLlaStopSession(); //if we processed the last request in the queue, stop LLA session
        uniqueLock.lock();
        auto tEnd = std::chrono::steady_clock::now();
      //  Print::PrintError(queue->name + " LLA session stopped, took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");
    }

    // wait for request, handle spurious wakeup properly
    while (queue->stack.empty())
    {
       // Print::PrintError(queue->name + " stack empty start\n");
       // Print::PrintError(queue->name + " clearQueue waiting");
        auto tStart = std::chrono::steady_clock::now();
        queue->conditionVar.wait(uniqueLock);
        auto tEnd = std::chrono::steady_clock::now();
        const std::chrono::time_point<std::chrono::system_clock> now = std::chrono::system_clock::now();
        const std::time_t t_c = std::chrono::system_clock::to_time_t(now);
       // Print::PrintError(queue->name + " clearQueue wakeup at " + std::asctime(std::localtime(&t_c)) + ", took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");

        // check if we have been woken up by the destructor
        if (queue->isFinished)
        {
            return;
        }
    }

    queue->isProcessing = true;

    pair<ProcessMessage*, ChainTopic*> request = queue->stack.front();
    queue->stack.pop_front();

    // at this point we do not need to access the queue further, so we release the lock to allow
    // other threads to add more requests while we process the current one
    uniqueLock.unlock();
  //  Print::PrintError(queue->name + " clearQueue unlocked");

    //do processing
    AlfRpcInfo* alfLink = request.first->getUseCru() ? request.second->alfLink.first : request.second->alfLink.second;
    alfLink->setTransaction(request);  //CAN bus backup

    Print::PrintVerbose(request.second->name, "Parsing message");

    vector<string> fullMessage;

    try
    {
      if (request.second->mapi == NULL)
      {
        fullMessage = request.first->generateFullMessage(*request.second->instruction);
      }
      else
      {
        fullMessage = vector<string>({ request.first->generateMapiMessage() });
      }
    }
    catch (exception& e)
    {
      string errorMessage = e.what();
      Print::PrintError(request.second->name, errorMessage);

      request.second->error->Update(errorMessage);
      Print::PrintError(request.second->name, "Updating error service!");

      queue->isProcessing = false;
      continue;
    }

    if (request.second->mapi != NULL && request.second->mapi->noRpcRequest)
    {
      Print::PrintVerbose(request.second->name, "Skipping RPC request");
      request.second->mapi->noRpcRequest = false; //reset noRpcRequest
      queue->isProcessing = false;
      continue;
    }
    else
    {
      bool errorOccured = false;

      auto tStart = std::chrono::steady_clock::now();
      for (size_t i = 0; i < fullMessage.size() && !errorOccured; i++)
      {
        char* buffer = strdup(fullMessage[i].c_str());

        do
        {
          auto tStartLla = std::chrono::steady_clock::now();
          if (!queue->checkLlaStartSession())
          {
            Print::PrintError(request.second->name, "Error starting LLA session!");
            request.second->error->Update("Error starting LLA session!");
            errorOccured = true;
            queue->isProcessing = false;
            continue;
          }
          auto tEndLla = std::chrono::steady_clock::now();
        //  Print::PrintError(queue->name + " LLA session started, took " + std::to_string(std::chrono::duration<double>(tEndLla - tStartLla).count()) + " s");

          Print::PrintVerbose(request.second->name, "Sending RPC request:\n" + string(buffer));
          alfLink->Send(buffer);

          errorOccured = request.first->getPollPattern()->at(i) == "ERROR";
        }
        while (!request.first->getPollPattern()->at(i).empty() && !errorOccured);

        free(buffer);
      }
      auto tEnd = std::chrono::steady_clock::now();
    //  Print::PrintError(queue->name + " message sent, took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");
    }
  }
}

void Queue::newRequest(pair<ProcessMessage*, ChainTopic*> request)
{
  //Print::PrintError(name + " newRequest start");
  auto tStart = std::chrono::steady_clock::now();
  unique_lock<mutex> lockGuard(stackMutex);
  auto tEnd = std::chrono::steady_clock::now();
 // Print::PrintError(name + " newRequest locked, took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");
  stack.push_back(request);
  const std::chrono::time_point<std::chrono::system_clock> now = std::chrono::system_clock::now();
  const std::time_t t_c = std::chrono::system_clock::to_time_t(now);
 // Print::PrintError(name + " newRequest pushed at " + std::asctime(std::localtime(&t_c)));

  lockGuard.unlock();
 // Print::PrintError(name + " newRequest unlocked");
  conditionVar.notify_one();
 // Print::PrintError(name + " newRequest notified");
}

size_t Queue::getStackSize()
{
    lock_guard<mutex> lockGuard(stackMutex);
    return stack.size();
}

void Queue::setLlaLock(LlaLock* llaLock)
{
    this->llaLock = llaLock;
}

LlaLock* Queue::getLlaLock()
{
    return this->llaLock;
}

bool Queue::checkLlaStartSession()
{
    if (!this->llaLock) //ignore LLA if not set
    {
        return true;
    }

    return this->llaLock->startLlaSession();
}

void Queue::checkLlaStopSession()
{
   // Print::PrintError(name + " checkLlaStopSession start\n");
    if (this->llaLock)
    {
      //  Print::PrintError(name + " checkLlaStopSession thislock before\n");
        this->llaLock->stopLlaSession();
      //  Print::PrintError(name + " checkLlaStopSession thislock after\n");
    }
}

bool Queue::processing()
{
    return this->isProcessing;
}

#include <ctime>
#include <chrono>
#include <iomanip>

#include "Fred/Mapi/indefinitemapi.h"
#include "Fred/mappedcommand.h"
#include "Fred/fredtopics.h"
#include "Parser/processmessage.h"
#include "Alfred/print.h"
#include "Fred/queue.h"
#include "Fred/alfrpcinfo.h"
#include <exception>

map<thread::id, IndefiniteMapi*> IndefiniteMapi::mappedThreads;

IndefiniteMapi::IndefiniteMapi()
{
    this->isFinished = false;
    this->executionThread = NULL;
    this->request = make_pair(string(""), false);
}

IndefiniteMapi::~IndefiniteMapi()
{
    this->isFinished = true;
    this->requestRecv.notify_one();

    if (this->executionThread)
    {
        this->executionThread->join();
        delete this->executionThread;
    }
}

void IndefiniteMapi::registerMapi(Fred* fred, string name)
{
    Mapi::registerMapi(fred, name);
    this->executionThread = new thread(&IndefiniteMapi::doExecution, this);
}

string IndefiniteMapi::processInputMessage(string input)
{
    return input;
}

string IndefiniteMapi::processOutputMessage(string output)
{
    unique_lock<mutex> sequenceLock(this->sequenceAccess);
    this->response = output;
    sequenceLock.unlock();
    this->sequenceRecv.notify_one();

    return "";
}

void IndefiniteMapi::doExecution()
{
    this->executionThreadId = this_thread::get_id();
    IndefiniteMapi::mappedThreads[this->executionThreadId] = this;

    while (!this->isFinished)
    {
        try
        {
            this->processExecution();
        }
        catch (const exception& e)
        {
            this->publishError(string("Error in process execution: ") + e.what());
        }
    }
}

string IndefiniteMapi::waitForRequest(bool &running)
{
    if (this_thread::get_id() != this->executionThreadId)
    {
        Print::PrintError("Cannot call waitForRequest from different thread");
        return "";
    }

    unique_lock<mutex> requestLock(this->requestAccess);
    // wait for a valid request to be available, check for spurious wakeups
    while (!this->request.second) {
      this->requestRecv.wait(requestLock);
    }

    if (this->isFinished)
    {
        running = false;
        return "";
    }

    running = true;

    pair<string, bool> request = this->request;
    this->request = make_pair(string(""), false);
    return request.second ? request.first : "";
}

bool IndefiniteMapi::isRequestAvailable(bool& running)
{
    if (this->isFinished)
    {
        running = false;
        return false;
    }

    running = true;

    lock_guard<mutex> lock(this->requestAccess);
    return this->request.second;
}

string IndefiniteMapi::getRequest()
{
    lock_guard<mutex> lock(this->requestAccess);
    pair<string, bool> request = this->request;
    this->request = make_pair(string(""), false);
    return request.second ? request.first : "";
}

string IndefiniteMapi::executeAlfSequence(string sequence)
{
    if (this->thisMapi->fakeLink)
    {
        return sequence;
    }

    if (this_thread::get_id() != this->executionThreadId)
    {
        Print::PrintError("Cannot call executeAlfSequence from different thread");
        return "";
    }

    const std::chrono::time_point<std::chrono::system_clock> now1 = std::chrono::system_clock::now();
    const std::time_t t_c1 = std::chrono::system_clock::to_time_t(now1);
  //  Print::PrintError(name + " executeAlfSequence sequence received at " + std::asctime(std::localtime(&t_c1)));


    bool useCru = dynamic_cast<MappedCommand*>(this->thisMapi->command)->getUseCru();
    AlfRpcInfo* alfRpcInfo = useCru ? this->thisMapi->alfLink.first : this->thisMapi->alfLink.second;
    if (alfRpcInfo == NULL)
    {
        string error = "Required ALF/CANALF not available!";
        Print::PrintError(name, error);
        return "failure\n" + error;
    }

    auto tStart = std::chrono::steady_clock::now();
    ProcessMessage* processMessage = new ProcessMessage(this, sequence, useCru, alfRpcInfo->getVersion());
    Queue* queue = useCru ? this->thisMapi->alfQueue.first : this->thisMapi->alfQueue.second;
    queue->newRequest(make_pair(processMessage, thisMapi));

    const std::chrono::time_point<std::chrono::system_clock> now2 = std::chrono::system_clock::now();
    const std::time_t t_c2 = std::chrono::system_clock::to_time_t(now2);
   // Print::PrintError(name + " executeAlfSequence request submitted at " + std::asctime(std::localtime(&t_c2)));

    // wait for the response, check for spurious wakeups
    unique_lock<mutex> sequenceLock(this->sequenceAccess);
    while (this->response == "") {
      this->sequenceRecv.wait(sequenceLock);
    }
    auto tEnd = std::chrono::steady_clock::now();

    const std::chrono::time_point<std::chrono::system_clock> now3 = std::chrono::system_clock::now();
    const std::time_t t_c3 = std::chrono::system_clock::to_time_t(now3);
 //   Print::PrintError(name + " executeAlfSequence response received at " + std::asctime(std::localtime(&t_c3)) + ", took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");

    string response = this->response;
    this->response = "";
    return response;
}

bool IndefiniteMapi::customMessageProcess()
{
    return true;
}

void IndefiniteMapi::requestReceived(string request)
{
    unique_lock<mutex> lock(this->requestAccess);
    this->request = make_pair(request, true);
    lock.unlock();
    this->requestRecv.notify_one();
}

IndefiniteMapi* IndefiniteMapi::getCurrentMapi()
{
    thread::id currentId = this_thread::get_id();
    if (IndefiniteMapi::mappedThreads.count(currentId))
    {
        return IndefiniteMapi::mappedThreads[currentId];
    }

    return NULL;
}

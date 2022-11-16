#include <algorithm>
#include "Fred/groupcommand.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"
#include "Fred/fredtopics.h"
#include "Fred/queue.h"
#include "Fred/mappedcommand.h"
#include "Fred/alfrpcinfo.h"

GroupCommand::GroupCommand(string name, Fred* fred, GroupTopic *topic): CommandString::CommandString(name, (ALFRED*)fred)
{
    this->topic = topic;
    this->isFinished = false;
    this->queueThread = new thread(processRequest, this);
    this->groupError = false;
}

GroupCommand::~GroupCommand()
{
    isFinished = true;
    lock.unlock();
    queueThread->join();
    delete queueThread;
}

const void* GroupCommand::Execution(void *value)
{
    if (!value)
    {
        Print::PrintError(topic->name, "Invalid request, no value received!");
    }

    Print::PrintVerbose(topic->name, "Received group command:\n");

    for (size_t i = 0; i < topic->chainTopics.size(); i++)
    {
        bool useCru = ((MappedCommand*)topic->chainTopics[i]->command)->getUseCru();
        AlfRpcInfo* alfRpcInfo = useCru ? topic->chainTopics[i]->alfLink.first : topic->chainTopics[i]->alfLink.second;
        if (alfRpcInfo == NULL)
        {
            string error = "Required ALF/CANALF not available!";
            Print::PrintError(name, error);
            topic->error->Update(error);
            Print::PrintError(topic->name, "Updating error service!");
            return NULL;
        }

        ProcessMessage* processMessage = new ProcessMessage(topic->inVars, topic->chainTopics[i]->placeId, this, useCru, alfRpcInfo->getVersion());

        Queue* queue = useCru ? this->topic->chainTopics[i]->alfQueue.first : this->topic->chainTopics[i]->alfQueue.second;
        queue->newRequest(make_pair(processMessage, this->topic->chainTopics[i]));
    }

    newRequest();

    return NULL;
}

void GroupCommand::processRequest(GroupCommand* command)
{
    command->lock.lock();

    while (1)
    {
        command->lock.lock();

        if (command->isFinished)
        {
            return;
        }

        while (command->received.size() < command->topic->chainTopics.size())
        {
            usleep(10);
        }

        string response;
        for (size_t i = 0; i < command->topic->unitIds.size(); i++)
        {
            response += command->received[command->topic->unitIds[i]];
            if (i < command->topic->unitIds.size() - 1) response += "\n";
        }

        if (command->groupError) 
        {           
            command->topic->error->Update(response); //_ERR
            Print::PrintError(command->topic->name, "Updating group error service!");
        }
        else
        {
            command->topic->service->Update(response); //_ANS
            Print::PrintVerbose(command->topic->name, "Updating group service!");
        }
        
        command->groupError = false;
        command->received.clear();
    }

}

void GroupCommand::newRequest()
{
    lock.unlock();
}

void GroupCommand::receivedResponse(ChainTopic *topic, string response, bool error)
{
    if (error) groupError = true;

    size_t idx = distance(this->topic->chainTopics.begin(), find(this->topic->chainTopics.begin(), this->topic->chainTopics.end(), topic));
    this->received[this->topic->unitIds[idx]] = response;
}

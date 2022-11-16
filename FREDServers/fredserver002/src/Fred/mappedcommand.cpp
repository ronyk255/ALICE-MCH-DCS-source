#include "Fred/mappedcommand.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"
#include "Fred/fredtopics.h"
#include "Fred/queue.h"
#include "Fred/Mapi/indefinitemapi.h"
#include "Fred/alfrpcinfo.h"

MappedCommand::MappedCommand(string name, Fred* fred, ChainTopic *topic, int32_t placeId): CommandString::CommandString(name, (ALFRED*)fred)
{
    this->topic = topic;
    this->placeId = placeId;
    this->useCru = true;
}

MappedCommand::~MappedCommand()
{

}

const void* MappedCommand::Execution(void *value)
{
    if (!value)
    {
        Print::PrintError(name, "Invalid request, no value received!");
    }

    string request(static_cast<char*>(value));

    Print::PrintVerbose(name, "Received command: \n" + request);

    if (this->topic->fakeLink)
    {
        if (this->topic->mapi == NULL)
        {
            Print::PrintError(name, "Cannot use fakeLink in non MAPI topic!");
            return NULL;
        }

        request = this->topic->mapi->processInputMessage(request);

        if (!this->topic->mapi->customMessageProcess())
        {
            string response = this->topic->mapi->processOutputMessage(request);
            if (!this->topic->mapi->noReturn)
            {
                if (this->topic->mapi->returnError)
                {
                    this->topic->error->Update(response);
                    Print::PrintError(this->topic->name, "Updating MAPI error service!");
                    this->topic->mapi->returnError = false;
                }
                else
                {
                    this->topic->service->Update(response);
                    Print::PrintVerbose(this->topic->name, "Updating MAPI service");
                }
            }
            else
            {
                Print::PrintVerbose(this->topic->name, "Mapi is noReturn");
                this->topic->mapi->noReturn = false;
            }
        }
        else
        {
            dynamic_cast<IndefiniteMapi*>(this->topic->mapi)->requestReceived(request);
        }

        return NULL;
    }

    AlfRpcInfo* alfRpcInfo = this->useCru ? this->topic->alfLink.first : this->topic->alfLink.second;
    if (alfRpcInfo == NULL)
    {
        string error = "Required ALF/CANALF not available!";
        Print::PrintError(name, error);
        topic->error->Update(error);
        Print::PrintError(topic->name, "Updating error service!");
        return NULL;
    }

    if (topic->mapi == NULL)
    {
        ProcessMessage* processMessage = new ProcessMessage(request, this->placeId, this->useCru, alfRpcInfo->getVersion());
        if (processMessage->isCorrect())
        {
            Queue* queue = this->useCru ? this->topic->alfQueue.first : this->topic->alfQueue.second;
            queue->newRequest(make_pair(processMessage, this->topic));
        }
        else
        {
            string error = "Invalid input received!";
            Print::PrintError(name, error);
            topic->error->Update(error);
            Print::PrintError(topic->name, "Updating error service!");
            delete processMessage;
        }
    }
    else
    {
        if (!this->topic->mapi->customMessageProcess())
        {
            ProcessMessage* processMessage = new ProcessMessage(topic->mapi, request, this->useCru, alfRpcInfo->getVersion());

            Queue* queue = this->useCru ? this->topic->alfQueue.first : this->topic->alfQueue.second;
            queue->newRequest(make_pair(processMessage, this->topic));
        }
        else
        {
            dynamic_cast<IndefiniteMapi*>(this->topic->mapi)->requestReceived(request);
        }
    }

    return NULL;
}

void MappedCommand::setUseCru(bool useCru)
{
    this->useCru = useCru;
}

bool MappedCommand::getUseCru()
{
    return this->useCru;
}

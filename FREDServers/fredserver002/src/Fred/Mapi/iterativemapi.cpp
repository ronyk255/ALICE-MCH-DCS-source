#include <iostream>
#include <string>
#include <algorithm>
#include <vector>
#include "Fred/fredtopics.h"
#include "Fred/fred.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"
#include "Fred/alfrpcinfo.h"

/*
 * Send a new request to the same MAPI topic 
 */
void Iterativemapi::newRequest(string request)
{
    bool useCru = dynamic_cast<MappedCommand*>(this->thisMapi->command)->getUseCru();
    AlfRpcInfo* alfRpcInfo = useCru ? this->thisMapi->alfLink.first : this->thisMapi->alfLink.second;
    if (alfRpcInfo == NULL)
    {
        string error = "Required ALF/CANALF not available!";
        Print::PrintError(name, error);
        thisMapi->error->Update(error);
        return;
    }

    ProcessMessage* processMessage = new ProcessMessage(this, request, useCru, alfRpcInfo->getVersion());
    Queue* queue = useCru ? this->thisMapi->alfQueue.first : this->thisMapi->alfQueue.second;
    queue->newRequest(make_pair(processMessage, thisMapi));
}

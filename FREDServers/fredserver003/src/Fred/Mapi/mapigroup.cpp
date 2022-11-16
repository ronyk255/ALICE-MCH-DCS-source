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
 * Send a new request to a group of MAPI topic 
 */
void Mapigroup::newMapiGroupRequest(vector<pair<string, string> > requests)
{
    FredTopics& topics = this->fred->getFredTopics();

    map<string, ChainTopic>& map = topics.getTopicsMap();

    for (size_t i = 0; i < requests.size(); i++)
    {
        auto it = map.find(requests[i].first);
        if (it == map.end())
        {
            Print::PrintError(requests[i].first + " requested in " + this->name + " is not a registered topic!");
        }
        else
        {
            ChainTopic& mapi = map[requests[i].first];
            bool useCru = dynamic_cast<MappedCommand*>(mapi.command)->getUseCru();
            AlfRpcInfo* alfRpcInfo = useCru ? mapi.alfLink.first : mapi.alfLink.second;
            if (alfRpcInfo == NULL)
            {
                string error = "Required ALF/CANALF not available!";
                Print::PrintError(name, error);
                thisMapi->error->Update(error);
                return;
            }

            ProcessMessage* processMessage = new ProcessMessage(mapi.mapi, requests[i].second, useCru, alfRpcInfo->getVersion());
            Queue* queue = useCru ? mapi.alfQueue.first : mapi.alfQueue.second;
            queue->newRequest(make_pair(processMessage, &mapi));
        }
    }
}

/*
 * Send a new request to a group of regular topic 
 */
void Mapigroup::newTopicGroupRequest(vector<pair<string, string> > requests)
{
    FredTopics& topics = this->fred->getFredTopics();

    map<string, ChainTopic>& map = topics.getTopicsMap();

    for (size_t i = 0; i < requests.size(); i++)
    {
        auto it = map.find(requests[i].first);
        if (it == map.end())
        {
            Print::PrintError(requests[i].first + " requested in " + this->name + " is not a registered topic!");
        }
        else
        {
            ChainTopic& topic = map[requests[i].first];

            int32_t placeId = map[requests[i].first].placeId;

            bool useCru = dynamic_cast<MappedCommand*>(topic.command)->getUseCru();
            AlfRpcInfo* alfRpcInfo = useCru ? topic.alfLink.first : topic.alfLink.second;
            if (alfRpcInfo == NULL)
            {
                string error = "Required ALF/CANALF not available!";
                Print::PrintError(name, error);
                thisMapi->error->Update(error);
                return;
            }

            ProcessMessage* processMessage = new ProcessMessage(requests[i].second, placeId, useCru, alfRpcInfo->getVersion());
            Queue* queue = useCru ? topic.alfQueue.first : topic.alfQueue.second;
            queue->newRequest(make_pair(processMessage, &topic));
        }
    }
}

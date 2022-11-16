#include <iostream>
#include <string>
#include <algorithm>
#include <vector>
#include "Fred/fredtopics.h"
#include "Fred/fred.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"
#include "Fred/llalock.h"

void Mapi::registerMapi(Fred* fred, string name)
{
    this->fred = fred;
    this->name = name;
    this->thisMapi = &fred->getFredTopics().getTopicsMap()[name];
}

Mapi::~Mapi()
{

}

void Mapi::publishAnswer(string message)
{
    thisMapi->service->Update(message);

    Print::PrintVerbose(name, "Updating MAPI service");
}

void Mapi::publishError(string error)
{
    thisMapi->error->Update(error);

    Print::PrintError(name, "Updating MAPI error service!");
}

bool Mapi::customMessageProcess()
{
    return false;
}

bool Mapi::startLlaOverride()
{
    if (thisMapi->alfQueue.first)
    {
        LlaLock* lla = thisMapi->alfQueue.first->getLlaLock();
        if (lla)
        {
            return lla->overrideLlaSession(true);
        }
    }

    return true;
}

void Mapi::stopLlaOverride()
{
    if (thisMapi->alfQueue.first)
    {
        LlaLock* lla = thisMapi->alfQueue.first->getLlaLock();
        if (lla)
        {
            lla->overrideLlaSession(false);
        }
    }
}

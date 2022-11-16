#include "Fred/llalock.h"
#include <unistd.h>
#include "Alfred/print.h"

LlaLock::LlaLock(const string& alf, int32_t serial, uint32_t repeat, uint32_t delay, vector<Queue*> queues, Fred* fred)
{
    this->repeat = repeat;
    this->delay = delay;
    this->queues = queues;
    this->fred = fred;
    this->hasLlaSession = false;
    this->overridenSession = false;

    this->startLla = dynamic_cast<LlaAlfRpcInfo*>(this->fred->GetRpcInfo(alf + "/SERIAL_" + to_string(serial) + "/LLA_SESSION_START"));
    this->stopLla = dynamic_cast<LlaAlfRpcInfo*>(this->fred->GetRpcInfo(alf + "/SERIAL_" + to_string(serial) + "/LLA_SESSION_STOP"));
}

bool LlaLock::startLlaSession()
{
    lock_guard<mutex> lock(this->sessionAccesss);

    if (this->hasLlaSession)
    {
        return true;
    }

    int attempt = 0;

    do
    {
        this->hasLlaSession = this->startLla->requestLlaSession(attempt >= this->repeat - 1);
        if (this->hasLlaSession)
        {
            break;
        }

        if (this->delay)
        {
            usleep(this->delay * 1000); //ms to us
        }
    }
    while (++attempt < this->repeat);

    return this->hasLlaSession;
}

bool LlaLock::stopLlaSession()
{
    lock_guard<mutex> lock(this->sessionAccesss);
	

    if (!this->hasLlaSession)
    { 
        return true;
    }

    if (this->overridenSession)
    {
        return false;
    }

    if (this->checkQueuesEmpty())
    {
        this->hasLlaSession = !this->stopLla->requestLlaSession(true);
		
    }

    return !this->hasLlaSession;
}

bool LlaLock::overrideLlaSession(bool enable)
{
    if (enable)
    {
        bool startStatus = this->startLlaSession();
        if (startStatus)
        {
            this->overridenSession = true;
        }

        return startStatus;
    }
    else
    {
        this->overridenSession = false;
        this->stopLlaSession();
        return true;
    }
}

bool LlaLock::checkQueuesEmpty()
{
    for (size_t i = 0; i < this->queues.size(); i++)
    {
        if (this->queues[i]->getStackSize() || this->queues[i]->processing())
        {
            return false;
        }
    }

    return true;
}

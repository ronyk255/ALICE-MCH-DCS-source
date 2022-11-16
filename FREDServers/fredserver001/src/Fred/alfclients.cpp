#include "Fred/alfclients.h"
#include "Fred/alfrpcinfo.h"
#include "Fred/crualfrpcinfo.h"
#include "Fred/llaalfrpcinfo.h"
#include "Fred/fred.h"
#include "Fred/llalock.h"

AlfClients::AlfClients(Fred *fred)
{
    this->fred = fred;
}

AlfClients::~AlfClients()
{
    for (auto alf = clients.begin(); alf != clients.end(); alf++)
    {
        for (auto serial = alf->second.begin(); serial != alf->second.end(); serial++)
        {
            for (auto endpoint = serial->second.begin(); endpoint != serial->second.end(); endpoint++)
            {
                for (auto link = endpoint->second.begin(); link != endpoint->second.end(); link++)
                {
                    delete link->second.queue;
                }
            }
        }
    }

    for (auto llaAlf = llaClients.begin(); llaAlf != llaClients.end(); llaAlf++)
    {
        for (auto serial = llaAlf->second.begin(); serial != llaAlf->second.end(); serial++)
        {
            delete serial->second.llaLock;
        }
    }
}

void AlfClients::registerAlf(Location::AlfEntry &entry)
{
    if (clients.count(entry.id) == 0)
    {
        clients[entry.id] = map<int32_t, map<int32_t, map<int32_t, Nodes> > >();
    }

    for (auto serial = entry.serials.begin(); serial != entry.serials.end(); serial++)
    {
        if (clients[entry.id].count(serial->first) == 0)
        {
            clients[entry.id][serial->first] = map<int32_t, map<int32_t, Nodes> >();
        }

        for (auto endpoint = serial->second.endpoints.begin(); endpoint != serial->second.endpoints.end(); endpoint++)
        {
            if (clients[entry.id][serial->first].count(endpoint->first) == 0)
            {
                clients[entry.id][serial->first][endpoint->first] = map<int32_t, Nodes>();
            }

            for (size_t linkIdx = 0; linkIdx < endpoint->second.links.size(); linkIdx++)
            {
                if (clients[entry.id][serial->first][endpoint->first].count(endpoint->second.links[linkIdx]) == 0)
                {
                    clients[entry.id][serial->first][endpoint->first][endpoint->second.links[linkIdx]] = createAlfInfo(entry.id, serial->first, endpoint->first, endpoint->second.links[linkIdx], entry.version, serial->second.cardType);
                }
            }
        }
    }
}

AlfClients::Nodes AlfClients::createAlfInfo(string id, int32_t serial, int32_t endpoint, int32_t link, Location::AlfEntry::Version version, Location::AlfEntry::SerialEntry::CardType cardType)
{
    Nodes nodes = { .sca = NULL, .swt = NULL, .ic = NULL, .crorc = NULL, .cru = NULL, .queue = NULL };
    string endpointStr = version == Location::AlfEntry::Version::v0 ? "" : ("/ENDPOINT_" + to_string(endpoint));

    if (cardType == Location::AlfEntry::SerialEntry::CardType::CRU)
    {
        if (link != -1)
        {
            nodes.swt = new AlfRpcInfo(id + "/SERIAL_" + to_string(serial) + endpointStr + "/LINK_" + to_string(link) + "/SWT_SEQUENCE", " ", this->fred, version);
            this->fred->RegisterRpcInfo(nodes.swt);

            if (id.find("ALF") == 0)
            {
                nodes.sca = new AlfRpcInfo(id + "/SERIAL_" + to_string(serial) + endpointStr + "/LINK_" + to_string(link) + "/SCA_SEQUENCE", " ", this->fred, version);
                this->fred->RegisterRpcInfo(nodes.sca);
                nodes.ic = new AlfRpcInfo(id + "/SERIAL_" + to_string(serial) + endpointStr + "/LINK_" + to_string(link) + "/IC_SEQUENCE", " ", this->fred, version);
                this->fred->RegisterRpcInfo(nodes.ic);
            }
        }
        else if (id.find("ALF") == 0) // CRU register sequence
        {
            nodes.cru = new AlfRpcInfo(id + "/SERIAL_" + to_string(serial) + "/REGISTER_SEQUENCE", " ", this->fred, version);
            this->fred->RegisterRpcInfo(nodes.cru);
        }
    }
    else if (cardType == Location::AlfEntry::SerialEntry::CardType::CRORC)
    {
        nodes.crorc = new AlfRpcInfo(id + "/SERIAL_" + to_string(serial) + endpointStr + "/LINK_" + to_string(link) + "/REGISTER_SEQUENCE", " ", this->fred, version);
        this->fred->RegisterRpcInfo(nodes.crorc);
    }

    string queueName = id + "/SERIAL_" + to_string(serial) + endpointStr + "/LINK_" + to_string(link);
    nodes.queue = new Queue(this->fred, queueName);

    return nodes;
}

void AlfClients::registerCruAlf(Location::AlfEntry& entry)
{
    if (cruClients.count(entry.id) == 0)
    {
        cruClients[entry.id] = map<int32_t, CruNodes>();
    }

    for (auto serial = entry.serials.begin(); serial != entry.serials.end(); serial++)
    {
        if (cruClients[entry.id].count(serial->first) == 0)
        {
            CruNodes cruNodes;
            cruNodes.patternPlayer = new CruAlfRpcInfo(entry.id + "/SERIAL_" + to_string(serial->first) + "/PATTERN_PLAYER", this->fred, ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER);

            this->fred->RegisterRpcInfo(cruNodes.patternPlayer);

            cruClients[entry.id][serial->first] = cruNodes;
        }
    }
}

void AlfClients::registerLlaAlf(LlaMapping::LlaEntry& entry)
{
    if (llaClients.count(entry.alfEntry.id) == 0)
    {
        llaClients[entry.alfEntry.id] = map<int32_t, LlaNodes>();
    }

    for (auto serial = entry.alfEntry.serials.begin(); serial != entry.alfEntry.serials.end(); serial++)
    {
        if (llaClients[entry.alfEntry.id].count(serial->first) == 0)
        {
            vector<Queue*> queues = this->getAlfCruQueues(entry.alfEntry.id, serial->first);
            if (queues.size())
            {
                LlaNodes llaNodes;
                llaNodes.llaStart = new LlaAlfRpcInfo(entry.alfEntry.id + "/SERIAL_" + to_string(serial->first) + "/LLA_SESSION_START", this->fred, ALFRED_TYPES::LLA_TYPES::START);
                llaNodes.llaStop = new LlaAlfRpcInfo(entry.alfEntry.id + "/SERIAL_" + to_string(serial->first) + "/LLA_SESSION_STOP", this->fred, ALFRED_TYPES::LLA_TYPES::STOP);

                this->fred->RegisterRpcInfo(llaNodes.llaStart);
                this->fred->RegisterRpcInfo(llaNodes.llaStop);

                llaNodes.llaLock = new LlaLock(entry.alfEntry.id, serial->first, entry.repeat, entry.delay, queues, this->fred);

                for (size_t i = 0; i < queues.size(); i++)
                {
                    queues[i]->setLlaLock(llaNodes.llaLock);
                }

                llaClients[entry.alfEntry.id][serial->first] = llaNodes;
            }
        }
    }
}

AlfRpcInfo* AlfClients::getAlfNode(string alf, int32_t serial, int32_t endpoint, int32_t link, Instructions::Type type)
{
    Nodes& nodes = clients[alf][serial][endpoint][link];

    switch (type)
    {
        case Instructions::Type::SCA:
            return nodes.sca;
        case Instructions::Type::SWT:
            return nodes.swt;
        case Instructions::Type::IC:
            return nodes.ic;
        case Instructions::Type::CRORC:
            return nodes.crorc;
        case Instructions::Type::CRU:
            return nodes.cru;
    }

    return NULL;
}

Queue* AlfClients::getAlfQueue(string alf, int32_t serial, int32_t endpoint, int32_t link)
{
    return clients[alf][serial][endpoint][link].queue;
}

vector<Queue*> AlfClients::getAlfCruQueues(string alf, int32_t serial)
{
    vector<Queue*> queues;

    if (clients.count(alf))
    {
        if (clients[alf].count(serial))
        {
            for (auto endpoint = clients[alf][serial].begin(); endpoint != clients[alf][serial].end(); endpoint++)
            {
                for (auto link = endpoint->second.begin(); link != endpoint->second.end(); link++)
                {
                    queues.push_back(link->second.queue);
                }
            }
        }
    }

    return queues;
}

CruAlfRpcInfo* AlfClients::getCruAlfNode(string alf, int32_t serial, ALFRED_TYPES::CRU_TYPES type)
{
    CruNodes& nodes = cruClients[alf][serial];

    switch (type)
    {
    case ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER:
        return nodes.patternPlayer;
    }

    return NULL;
}

vector<CruAlfRpcInfo*> AlfClients::getAllCruRpcs()
{
    vector<CruAlfRpcInfo*> rpcInfos;

    for (auto alf = this->cruClients.begin(); alf != this->cruClients.end(); alf++)
    {
        for (auto serial = alf->second.begin(); serial != alf->second.end(); serial++)
        {
            rpcInfos.push_back(serial->second.patternPlayer);
        }
    }

    return rpcInfos;
}

vector<LlaAlfRpcInfo*> AlfClients::getAllLlaRpcs()
{
    vector<LlaAlfRpcInfo*> rpcInfos;

    for (auto alf = this->llaClients.begin(); alf != this->llaClients.end(); alf++)
    {
        for (auto serial = alf->second.begin(); serial != alf->second.end(); serial++)
        {
            rpcInfos.push_back(serial->second.llaStart);
            rpcInfos.push_back(serial->second.llaStop);
        }
    }

    return rpcInfos;
}

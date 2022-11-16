#ifndef ALFCLIENTS_H
#define ALFCLIENTS_H

#include <string>
#include <vector>
#include <map>

#include "Fred/Config/location.h"
#include "Fred/Config/instructions.h"
#include "Fred/queue.h"
#include "Alfred/rpcinfo.h"
#include "Fred/Config/llamapping.h"

using namespace std;

class AlfRpcInfo;
class CruAlfRpcInfo;
class LlaAlfRpcInfo;
class LlaLock;

class AlfClients
{
public:
    struct Nodes
    {
        AlfRpcInfo *sca, *swt, *ic, *crorc, *cru;
        Queue *queue;
    };

    struct CruNodes
    {
        CruAlfRpcInfo *patternPlayer;
    };

    struct LlaNodes
    {
        LlaAlfRpcInfo *llaStart, *llaStop;
        LlaLock *llaLock;
    };

private:
    map<string, map<int32_t, map<int32_t, map<int32_t, Nodes> > > > clients; //ALF,SERIAL,ENDPOINT,LINK
    map<string, map<int32_t, CruNodes> > cruClients; //ALF,SERIAL
    map<string, map<int32_t, LlaNodes> > llaClients; //ALF,SERIAL
    Fred* fred;

public:
    AlfClients(Fred* fred);
    ~AlfClients();

    void registerAlf(Location::AlfEntry& entry);
    Nodes createAlfInfo(string id, int32_t serial, int32_t endpoint, int32_t link, Location::AlfEntry::Version version, Location::AlfEntry::SerialEntry::CardType cardType);
    void registerCruAlf(Location::AlfEntry& entry);
    void registerLlaAlf(LlaMapping::LlaEntry &entry);

    AlfRpcInfo* getAlfNode(string alf, int32_t serial, int32_t endpoint, int32_t link, Instructions::Type type);
    Queue* getAlfQueue(string alf, int32_t serial, int32_t endpoint, int32_t link);
    vector<Queue*> getAlfCruQueues(string alf, int32_t serial);

    CruAlfRpcInfo* getCruAlfNode(string alf, int32_t serial, ALFRED_TYPES::CRU_TYPES type);

    vector<CruAlfRpcInfo*> getAllCruRpcs();
    vector<LlaAlfRpcInfo*> getAllLlaRpcs();
};

#endif // ALFCLIENTS_H

#ifndef __RPC
#define __RPC

#include <cstdlib>
#include <string>
#include <vector>
#include <dim/dis.hxx>

#include "Alfred/types.h"

using namespace std;

class Service;
class Client;
class ALFRED;

class Rpc
{
protected:
    static vector<string> names;
    static void RemoveElement(const string& name);

    ALFRED_TYPES::DIM_TYPE type;
    string name;
    ALFRED* alfred;

    Rpc(string name, ALFRED* alfred);

    Service* serviceCallback;
    Client* clientCallback;

    virtual const void* Execution(void* value);

public:
    virtual ~Rpc();

    static bool AlreadyRegistered(const string& name);

    void ConnectService(Service* serviceCallback);
    void ConnectClient(Client* clientCallback);

    void CallService(string name, void* value);
    void CallClient(string name, void* value);

    ALFRED_TYPES::DIM_TYPE Type();
    string Name();
    ALFRED* Parent();
};

/*----------------------------------------------------------------------------------------------*/

class RpcInt: public Rpc, public DimRpc
{
private:
    int value;
    int noLink = 0;

    void rpcHandler();

public:
    RpcInt(string name, ALFRED* alfred);
    ~RpcInt();
};

/*----------------------------------------------------------------------------------------------*/

class RpcFloat: public Rpc, public DimRpc
{
private:
    float value;
    float noLink = 0.0;

    void rpcHandler();

public:
    RpcFloat(string name, ALFRED* alfred);
    ~RpcFloat();
};

/*----------------------------------------------------------------------------------------------*/

class RpcString: public Rpc, public DimRpc
{
private:
    string value;
    char noLink[1];

    void rpcHandler();

public:
    RpcString(string name, ALFRED* alfred);
    ~RpcString();
};

/*----------------------------------------------------------------------------------------------*/

class RpcData: public Rpc, public DimRpc
{
private:
    void* value;
    size_t size;
    char noLink = '\0';

    void rpcHandler();

public:
    RpcData(string name, ALFRED* alfred, size_t size, string formatIn, string formatOut);
    ~RpcData();
};

#endif

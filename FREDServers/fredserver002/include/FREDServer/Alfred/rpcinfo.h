#ifndef __RPCINFO
#define __RPCINFO

#include <cstdlib>
#include <string>
#include <vector>
#include <utility>
#include <dim/dic.hxx>

#include "Alfred/types.h"

using namespace std;

class Service;
class Client;
class ALFRED;

class RpcInfo
{
protected:
    static vector<pair<string, string> > names;
    static void RemoveElement(const string& name, const string& dns);

    DimRpcInfo* rpcInfo;
    ALFRED_TYPES::DIM_TYPE type;
    string name, dns;
    ALFRED* alfred;

    RpcInfo(string name, string dns, ALFRED* alfred);

    Service* serviceCallback;
    Client* clientCallback;

    virtual const void* Execution(void* value);

public:
    virtual ~RpcInfo();

    static bool AlreadyRegistered(const string& name, const string& dns);

    void ConnectService(Service* serviceCallback);
    void ConnectClient(Client* clientCallback);

    void CallService(string name, void* value);
    void CallClient(string name, void* value);

    ALFRED_TYPES::DIM_TYPE Type();
    string Name();
    string Dns();
    ALFRED* Parent();

    void* Send(void* value);
};

/*----------------------------------------------------------------------------------------------*/

class RpcInfoInt: public RpcInfo
{
public:
    RpcInfoInt(string name, string dns, ALFRED* alfred);
    ~RpcInfoInt();

    void* Send(int value);
};

/*----------------------------------------------------------------------------------------------*/

class RpcInfoFloat: public RpcInfo
{
public:
    RpcInfoFloat(string name, string dns, ALFRED* alfred);
    ~RpcInfoFloat();

    void* Send(float value);
};

/*----------------------------------------------------------------------------------------------*/

class RpcInfoString: public RpcInfo
{
private:
    char noLink[20];

public:
    RpcInfoString(string name, string dns, ALFRED* alfred);
    ~RpcInfoString();

    void* Send(char *value);
};

/*----------------------------------------------------------------------------------------------*/

class RpcInfoData: public RpcInfo
{
private:
    size_t size;

public:
    RpcInfoData(string name, string dns, ALFRED* alfred, size_t size);
    ~RpcInfoData();

    void* Send(void* value);
};

#endif

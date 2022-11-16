#ifndef __DATABASE_INTERFACE__
#define __DATABASE_INTERFACE__

#include <occi/occi.h>
#include "multitype.h"
#include <vector>
#include <mutex>

using namespace std;
using namespace oracle::occi;

class DatabaseInterface
{
private:
    static DatabaseInterface* instance;

    string user, password, connString;

    Environment* environment;
    Connection* connection;
    recursive_mutex dbMutex;

    bool reconnect();

public:
    DatabaseInterface(const string& user, const string& password, const string& connString);
    ~DatabaseInterface();

    bool connect();

    static bool isConnected();
    static bool isConnected(string& message);

    static vector<vector<MultiBase*> > executeQuery(const string& query, bool& status, string& message);
    static vector<vector<MultiBase*> > executeQuery(const string& query, bool& status);
    static vector<vector<MultiBase*> > executeQuery(const string& query);

    static void clearQueryResult(vector<vector<MultiBase*> >& result);

    static bool executeUpdate(const string& update, string& message);
    static bool executeUpdate(const string& update);

    static void commitUpdate(bool commit = true);
};

#endif

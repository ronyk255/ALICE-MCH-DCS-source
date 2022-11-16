#ifndef FRED_H
#define FRED_H

#include "Alfred/alfred.h"
#include "Fred/section.h"
#include "Fred/alfclients.h"
#include "Fred/fredtopics.h"
#include "Fred/Mapi/mapi.h"
#include "Fred/Mapi/iterativemapi.h"
#include "Fred/Mapi/mapigroup.h"
#include "Database/databaseinterface.h"

class Fred: public ALFRED
{
private:
    static void termFred(int);
    static bool terminate;
    void generateAlfs();
    void generateTopics();
    void checkAlfs();

    vector<Section> sections, cruSections;
    AlfClients alfClients;
    FredTopics fredTopics;

    string fredDns;
    DatabaseInterface* databaseInterface;

public:
    Fred(bool parseOnly, map<string, string> config, string mainDirectory);
    ~Fred();
    static map<string, string> readConfigFile();
    static bool commandLineArguments(int argc, char** argv);
    static void printHelp();

    AlfClients &getAlfClients();
    FredTopics &getFredTopics();

    string getFredDns();

    void registerMapiObject(string topic, Mapi* mapi, bool createFakeLink = false);
    void Start();
};

#endif // FRED_H

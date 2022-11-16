#include "Fred/fred.h"
#include <signal.h>
#include <fstream>
#include <exception>
#include <getopt.h>
#include "Alfred/print.h"
#include "Parser/parser.h"
#include "Fred/Config/mapping.h"
#include "Fred/Config/llamapping.h"
#include "Fred/cruregistercommand.h"
#include "Fred/Mapi/mapi.h"
#include "Fred/Mapi/iterativemapi.h"
#include "Fred/Mapi/mapigroup.h"
#include "Alfred/dimutilities.h"
#include "Fred/alfrpcinfo.h"
#include "Fred/llaalfrpcinfo.h"

bool Fred::terminate = false;

/*
 * Fred constructor
 */
Fred::Fred(bool parseOnly, map<string, string> config, string mainDirectory): ALFRED::ALFRED(config["NAME"], config["DNS"], parseOnly), alfClients(this), fredTopics(this)
{
    signal(SIGINT, &termFred);

    this->fredDns = config["DNS"];
    this->databaseInterface = NULL;

    if (config["DB_CONN"] != "" && config["DB_USER"] != "" && config["DB_PASS"] != "")
    {
        Print::PrintInfo("Connecting to database " + config["DB_USER"] + ".");
        this->databaseInterface = new DatabaseInterface(config["DB_USER"], config["DB_PASS"], config["DB_CONN"]);

        if (this->databaseInterface->connect())
        {
            Print::PrintInfo("Successfully connected to " + config["DB_USER"] + ".");
        }
        else
        {
            Print::PrintError("Cannot connect to " + config["DB_USER"] + "!");
        }
    }

    Print::PrintInfo("Parsing started.");
    try //parsing
    {
        Parser parser(mainDirectory);
        sections = parser.parseSections();
        cruSections = parser.parseCruSections();

        if(parser.badFiles)
        {
            Print::PrintError("Parser discovered errors! (See output above)");
            exit(EXIT_FAILURE);
        }
    }
    catch (exception& e)
    {
        Print::PrintError("Error occured during parsing configuration files!");
        exit(EXIT_FAILURE);
    }

    if (parseOnly)
    {
        Print::PrintInfo("Parsing completed! No problems discovered.");
        exit(EXIT_SUCCESS);
    }

    Print::PrintInfo("Parsing Completed. Starting FRED.");

    generateAlfs();
    generateTopics();
    checkAlfs();

    Print::PrintInfo("FRED running.");
}

Fred::~Fred()
{
    if (this->databaseInterface)
    {
        delete this->databaseInterface;
    }
}

/*
 * Read FRED name, DIM DNS and DB config from fred.conf
 */
map<string, string> Fred::readConfigFile()
{
    try
    {
        vector<string> lines = Parser::readFile("fred.conf", "./config");

        map<string, string> config = { { "NAME", "" }, { "DNS", "" }, { "DB_CONN", "" }, { "DB_USER", "" }, { "DB_PASS", "" } };

        for (size_t i = 0; i < lines.size(); i++)
        {
            string left = lines[i].substr(0, lines[i].find("="));
            string right = lines[i].substr(lines[i].find("=") + 1);

            config[left] = right;
        }

        if (config["NAME"] != "" && config["DNS"] != "")
        {
            return config;
        }
    }
    catch (exception& e)
    {
        Print::PrintError("Cannot load FRED config file!");
        exit(-1);
    }

    Print::PrintError("Invalid config file!");
    exit(-1);
}

void Fred::termFred(int)
{
    Print::PrintWarning("Closing FRED!");
    Fred::terminate = true;
}

void Fred::generateAlfs()
{
    for (size_t i = 0; i < sections.size(); i++)
    {
        map<string, Location::AlfEntry>& alfs = sections[i].mapping.alfList();
        for (auto alf = alfs.begin(); alf != alfs.end(); alf++)
        {
            alfClients.registerAlf(alf->second);
        }
    }

    for (size_t i = 0; i < cruSections.size(); i++)
    {
        map<string, Location::AlfEntry>& cruAlfs = cruSections[i].cruMapping.alfList();
        for (auto cruAlf = cruAlfs.begin(); cruAlf != cruAlfs.end(); cruAlf++)
        {
            alfClients.registerCruAlf(cruAlf->second);
        }

        vector<LlaMapping::LlaEntry>& llaAlfs = cruSections[i].llaMapping.alfList();
        for (auto llaAlf = llaAlfs.begin(); llaAlf != llaAlfs.end(); llaAlf++)
        {
            alfClients.registerLlaAlf(*llaAlf);
        }
    }
}

void Fred::generateTopics()
{
    for (size_t i = 0; i < sections.size(); i++)
    {
        vector<Mapping::Unit>& units = sections[i].mapping.getUnits();
        for (auto unit = units.begin(); unit != units.end(); unit++)
        {
            fredTopics.registerUnit(sections[i].getName(), *unit, sections[i].instructions);
        }

        vector<Groups::Group>& groups = sections[i].groups.getGroups();
        for (auto group = groups.begin(); group != groups.end(); group++)
        {
            fredTopics.registerGroup(sections[i].getName(), *group);
        }
    }

    for (size_t i = 0; i < cruSections.size(); i++)
    {
        vector<CruMapping::CruUnit>& cruUnits = cruSections[i].cruMapping.getCruUnits();
        for (auto cruUnit = cruUnits.begin(); cruUnit != cruUnits.end(); cruUnit++)
        {
            //RegisterCommand(new CruRegisterCommand(ALFRED_TYPES::CRU_TYPES::WRITE, cruUnit->cruUnitName, alfClients.getCruAlfNode(cruUnit->alf.alfId, cruUnit->alf.serialId, ALFRED_TYPES::CRU_TYPES::WRITE), this));
            //RegisterCommand(new CruRegisterCommand(ALFRED_TYPES::CRU_TYPES::READ, cruUnit->cruUnitName, alfClients.getCruAlfNode(cruUnit->alf.alfId, cruUnit->alf.serialId, ALFRED_TYPES::CRU_TYPES::READ), this));
            RegisterCommand(new CruRegisterCommand(ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER, cruUnit->cruUnitName, alfClients.getCruAlfNode(cruUnit->alf.alfId, cruUnit->alf.serialId, ALFRED_TYPES::CRU_TYPES::PATTERN_PLAYER), this));
        }
    }
}

void Fred::checkAlfs()
{
    vector<string> services;

    map<string, ChainTopic> topicsMapi = fredTopics.getTopicsMap();
    for (auto topic = topicsMapi.begin(); topic != topicsMapi.end(); topic++)
    {
        if (topic->second.alfLink.first)
        {
            services.push_back(topic->second.alfLink.first->getName());
        }

        if (topic->second.alfLink.second)
        {
            services.push_back(topic->second.alfLink.second->getName());
        }
    }

    vector<CruAlfRpcInfo*> cruRpcInfos = this->alfClients.getAllCruRpcs();
    for (size_t i = 0; i < cruRpcInfos.size(); i++)
    {
        services.push_back(cruRpcInfos[i]->getName());
    }

    vector<LlaAlfRpcInfo*> llaRpcInfos = this->alfClients.getAllLlaRpcs();
    for (size_t i = 0; i < llaRpcInfos.size(); i++)
    {
        services.push_back(llaRpcInfos[i]->getName());
    }

    DimUtilities::checkServices(services);
}

AlfClients& Fred::getAlfClients()
{
    return alfClients;
}

FredTopics& Fred::getFredTopics()
{
    return fredTopics;
}

string Fred::getFredDns()
{
    return fredDns;
}

void Fred::registerMapiObject(string topic, Mapi* mapi, bool createFakeLink)
{
    fredTopics.registerMapiObject(topic, mapi, createFakeLink);
    mapi->registerMapi(this, topic);
}

/*
 * Compute eventual command line arguments, return true if FRED is in parse only mode
 */
bool Fred::commandLineArguments(int argc, char** argv)
{
    struct option long_options[] =
    {
        {"verbose", no_argument, NULL, 'v'},
        {"log", required_argument, NULL, 'l'},
        {"help", no_argument, NULL, 'h'},
        {"parse", no_argument, NULL, 'p'},
        {NULL, 0, NULL, 0}
    };

    bool parseOnly = false;
    string logFilePath;

    int c;
    while ((c = getopt_long(argc, argv, "vl:hp" ,long_options, 0)) != -1)
    {
        switch (c)
        {
            case 'v':
                Print::setVerbose(true);
                Print::PrintWarning("FRED is verbose!");
                break;
            case 'l':
                if (!optarg)
                {
                    Print::PrintError("Argument \"log\" requires parameter!");
                    exit(-1);
                }
                logFilePath = optarg;
                break;
            case 'h':
                printHelp();
                exit(0);
                break;
            case 'p':
                parseOnly = true;
                Print::PrintWarning("Parse only mode!");
                break;
            case '?':
            default:
                Print::PrintError("Invalid argument detected!");
                printHelp();
                exit(-1);
        }
    }

    if (!logFilePath.empty())
    {
        ofstream logFile;
        logFile.open(logFilePath, ios_base::app);

        if (logFile)
        {
            Print::PrintInfo("FRED launched, logging to " + logFilePath); //inform user
            Print::setLogFile(logFilePath);
            Print::PrintInfo("FRED launched, logging to " + logFilePath); //inform via log file

            logFile.close();
        }
        else
        {
            Print::PrintError("FRED launched, log file " + logFilePath + " is not writable, falling back to standard output!");
        }
    }
    else
    {
        Print::PrintInfo("FRED launched!");
    }

    return parseOnly;
}

void Fred::printHelp()
{
    cout << "Usage: FREDServer [OPTIONS]\n\n"
        << "Optional arguments:\n"
        << "\t-v, --verbose\t\t\t\tVerbose log\n"
        << "\t-l, --log\t\t<file>\t\tLog output to file <file>\n"
        << "\t-p, --parse\t\t\t\tParse only mode\n"
        << "\t-h, --help\t\t\t\tShow this help\n";
}

void Fred::Start()
{
    StartOnce();

    while (!Fred::terminate)
    {
        usleep(100000);
    }
}

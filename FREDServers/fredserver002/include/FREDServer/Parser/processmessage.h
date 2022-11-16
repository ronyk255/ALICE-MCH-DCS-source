#ifndef PROCESSMESSAGE_H
#define PROCESSMESSAGE_H

#include <string>
#include <vector>
#include "Fred/Config/instructions.h"
#include "Fred/Mapi/mapi.h"
#include "Fred/Mapi/iterativemapi.h"
#include "Fred/Mapi/mapigroup.h"
#include "Fred/Config/location.h"

using namespace std;

struct ChainTopic;
struct GroupCommand;

class ProcessMessage
{
private:
    bool correct;
    vector<vector<double> > input;
    vector<string> outputPattern;
    vector<string> pollPattern;
    string fullMessage;
    GroupCommand* groupCommand;
    Mapi* mapi;
    bool useCru;
    Location::AlfEntry::Version alfVersion;


    bool checkMessage(string& message);

public:
    static const string SUCCESS, FAILURE;

    void parseInputVariables(string& line, vector<string>& inVars, int32_t iteration);

    ProcessMessage(string message, int32_t placeId, bool useCru, Location::AlfEntry::Version alfVersion);
    ProcessMessage(map<string, vector<double> > inVars, int32_t placeId, GroupCommand* groupCommand, bool useCru, Location::AlfEntry::Version alfVersion);
    ProcessMessage(Mapi* mapi, string input, bool useCru, Location::AlfEntry::Version alfVersion);
    int32_t getMultiplicity();
    bool isCorrect();
    vector<vector<unsigned long> > readbackValues(const string &message, Instructions::Instruction& instructions);
    vector<double> calculateReadbackResult(vector<vector<unsigned long> >& result, Instructions::Instruction& instructions);
    bool checkLink(string message, ChainTopic& chainTopic);
    void evaluateMessage(string message, ChainTopic& chainTopic, bool ignoreStatus = false);
    string generateMapiMessage();
    void evaluateMapiMessage(string message, ChainTopic& chainTopic);
    vector<string> generateFullMessage(Instructions::Instruction& instructions);
    string valuesToString(vector<vector<unsigned long> > values, int32_t multiplicity, Instructions::Type type);
    uint32_t getReturnWidth(Instructions::Type type);
    void updateResponse(ChainTopic& chainTopic, string response, bool error);
    vector<string>* getPollPattern();
    bool getUseCru();
    Location::AlfEntry::Version getAlfVersion();
};

#endif // PROCESSMESSAGE_H

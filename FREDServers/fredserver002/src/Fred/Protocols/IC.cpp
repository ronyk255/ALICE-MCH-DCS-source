#include <cctype>
#include <math.h>
#include <algorithm>
#include <string>
#include <iomanip>
#include <sstream>
#include "Alfred/print.h"
#include "Parser/utility.h"
#include "Fred/Config/instructions.h"
#include "Fred/Protocols/IC.h"

void IC::ICpad(string& line)
{
    vector<string> icParts = Utility::splitString(line, ",");
    if (icParts.size() != 1 && icParts.size() != 2)
    {
        throw runtime_error("IC command must have one or two parts!");
    }

    vector<uint64_t> icData;
    for (size_t i = 0; i < icParts.size(); i++)
    {
        if (icParts[i].find("0x") == 0) icParts[i] = icParts[i].substr(2); //remove eventual "0x"
        icData.push_back(stoull(icParts[i], NULL, 16));
    }

    if (icData[0] > 0xffff) throw runtime_error("IC 16 bit address exceeded: 0x" + icParts[0]);
    
    stringstream ss;
    ss << "0x" << setw(4) << setfill('0') << hex << icData[0];
    if (icData.size() == 2)
    {
        if (icData[1] > 0xff) throw runtime_error("IC 8 bit value exceeded: 0x" + icParts[1]);
        ss << ",0x" << setw(2) << setfill('0') << hex << icData[1];
        ss << ",write";
    }
    else
    {
        ss << ",read";
    }

    line = ss.str();
}

vector<string> IC::generateMessage(Instructions::Instruction& instructions, vector<string>& outputPattern, vector<string>& pollPattern, ProcessMessage* processMessage)
{
    bool parseInVar = instructions.inVars.size() > 0;

    int32_t multiplicity = processMessage->getMultiplicity();
    size_t messageSize = instructions.message.size();

    vector<string> result;
    string message;

    for (int32_t m = 0; m < multiplicity; m++)
    {
        for (size_t i = 0; i < messageSize; i++)
        {
            string outVar;
            string line = instructions.message[i]; //add raw user line

            if (parseInVar) processMessage->parseInputVariables(line, instructions.inVars, m); //parse invariables

            size_t atPos = line.find('@');
            if (atPos != string::npos) //user read @OUT_VAR
            {
                outVar = line.substr(atPos + 1);

                line.erase(atPos); //remove @OUT_VAR

                ICpad(line);

                outputPattern.push_back(outVar);

            }
            else //user write
            {
                outputPattern.push_back("");

                ICpad(line);
            }
            message += line + "\n";
        }
    }

    if (message.size())
    {
        message.erase(message.size() - 1);
        pollPattern.push_back("");
    }
    return vector<string>({ message });
}

void IC::checkIntegrity(const string& request, const string& response)
{
    for (size_t i = 0; i < response.size(); i++)
    {
        if (!(isxdigit(response[i]) || response[i] == '\n' || response[i] == 'x'))
        {
            throw runtime_error("IC: Invalid character received in RPC data:\n" + response + "\n");
        }
    }

    vector<string> reqVec = Utility::splitString(request, "\n");
    vector<string> resVec = Utility::splitString(response, "\n");

    if (reqVec.size() != resVec.size())
    {
        throw runtime_error("IC: Invalid number of lines received!");
    }
}

vector<vector<unsigned long> > IC::readbackValues(const string& message, const vector<string>& outputPattern, Instructions::Instruction& instructions)
{
    vector<string>& vars = instructions.vars;
    vector<string> splitted = Utility::splitString(message, "\n");

    vector<unsigned long> values;
    for (size_t i = 0; i < splitted.size(); i++)
    {
        values.push_back(stoul(splitted[i].substr(splitted[i].size() - IC::getReturnWidth()), NULL, 16)); //last 8
    }

    vector<vector<unsigned long> > results(vars.size(), vector<unsigned long>());
    for (size_t i = 0; i < values.size(); i++)
    {
        if (outputPattern[i] != "") //if there is an outvar in the request line
        {
            size_t id = distance(vars.begin(), find(vars.begin(), vars.end(), outputPattern[i]));
            results[id].push_back(values[i]);
        }
    }

    return results;
}

uint32_t IC::getReturnWidth()
{
    return 8;
}

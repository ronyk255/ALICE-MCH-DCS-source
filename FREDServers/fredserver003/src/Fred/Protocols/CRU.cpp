#include <cctype>
#include <math.h>
#include <algorithm>
#include <string>
#include <iomanip>
#include <sstream>
#include "Alfred/print.h"
#include "Parser/utility.h"
#include "Fred/Config/instructions.h"
#include "Fred/Protocols/CRU.h"

void CRU::CRUpad(string& line)
{
    vector<string> crorcParts = Utility::splitString(line, ",");
    if (crorcParts.size() != 1 && crorcParts.size() != 2)
    {
        throw runtime_error("CRU command must have one or two parts!");
    }

    vector<uint64_t> cruData;
    for (size_t i = 0; i < crorcParts.size(); i++)
    {
        if (crorcParts[i].find("0x") == 0) crorcParts[i] = crorcParts[i].substr(2); //remove eventual "0x"
        cruData.push_back(stoull(crorcParts[i], NULL, 16));
        if (cruData.back() > 0xffffffff)
        {
            throw runtime_error("CRU 32 bits exceeded!");
        }
    }

    stringstream ss;
    ss << "0x" << setw(8) << setfill('0') << hex << cruData[0];
    if (cruData.size() == 2)
    {
        ss << ",0x" << setw(8) << setfill('0') << hex << cruData[1];
    }

    line = ss.str();
}

vector<string> CRU::generateMessage(Instructions::Instruction& instructions, vector<string>& outputPattern, vector<string>& pollPattern, ProcessMessage* processMessage)
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

                CRUpad(line);

                outputPattern.push_back(outVar);

            }
            else //user write
            {
                outputPattern.push_back("");

                CRUpad(line);
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

void CRU::checkIntegrity(const string& request, const string& response)
{
    for (size_t i = 0; i < response.size(); i++)
    {
        if (!(isxdigit(response[i]) || response[i] == '\n' || response[i] == 'x'))
        {
            throw runtime_error("CRU: Invalid character received in RPC data:\n" + response + "\n");
        }
    }

    vector<string> reqVec = Utility::splitString(request, "\n");
    vector<string> resVec = Utility::splitString(response, "\n");

    if (reqVec.size() != resVec.size())
    {
        throw runtime_error("CRU: Invalid number of lines received!");
    }
}

vector<vector<unsigned long> > CRU::readbackValues(const string& message, const vector<string>& outputPattern, Instructions::Instruction& instructions)
{
    vector<string>& vars = instructions.vars;
    vector<string> splitted = Utility::splitString(message, "\n");

    vector<unsigned long> values;
    for (size_t i = 0; i < splitted.size(); i++)
    {
        values.push_back(stoul(splitted[i].size() > 4 ? splitted[i].substr(splitted[i].size() - CRU::getReturnWidth()) : splitted[i], NULL, 16)); //last 4 or 0
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

uint32_t CRU::getReturnWidth()
{
    //to be defined
    return 4;
}

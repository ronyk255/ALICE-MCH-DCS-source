#include <cctype>
#include <math.h>
#include <algorithm>
#include <string>
#include <iomanip>
#include <sstream>
#include "Alfred/print.h"
#include "Parser/utility.h"
#include "Fred/Config/instructions.h"
#include "Fred/Protocols/SCA.h"

bool SCA::SCApad(string& line)
{
    if (line == "svl_connect")
    {
        return true;
    }

    if (line == "svl_reset" || line == "sc_reset")
    {
        return false;
    }

    vector<string> scaParts = Utility::splitString(line, ",");
    if (scaParts.size() != 2)
    {
        throw runtime_error("SCA comma is missing or more than one comman occured!");
    }

    if (scaParts[1] == "wait") //SCA wait
    {
        int32_t wait;

        try
        {
            wait = stoi(scaParts[0]);
        }
        catch (invalid_argument& e)
        {
            throw runtime_error("SCA invalid wait value");
        }

        if (wait <= 0)
        {
            throw runtime_error("SCA invalid wait value");
        }

        line = to_string(wait) + ",wait";
        return true;
    }

    uint64_t command = stoull(scaParts[0], NULL, 16);
    uint64_t data = stoull(scaParts[1], NULL, 16);
    if (command > 0xffffffff || data > 0xffffffff)
    {
        throw runtime_error("SCA 32 bits exceeded!");
    }

    stringstream ss;
    ss << "0x" << setw(8) << setfill('0') << hex << command << "," << "0x" << setw(8) << setfill('0') << hex << data;
    line = ss.str();
    return true;
}

vector<string> SCA::generateMessage(Instructions::Instruction& instructions, vector<string>& outputPattern, vector<string>& pollPattern, ProcessMessage* processMessage)
{
    string message;
    bool parseInVar = instructions.inVars.size() > 0;

    int32_t multiplicity = processMessage->getMultiplicity();
    size_t messageSize = instructions.message.size();

    vector<string> result;

    for (int32_t m = 0; m < multiplicity; m++)
    {
        for (size_t i = 0; i < messageSize; i++)
        {
            string outVars;
            string line = instructions.message[i];

            if (parseInVar) processMessage->parseInputVariables(line, instructions.inVars, m); //parse IN_VARs

            size_t dolPos = line.find('$'); //user poll
            if (dolPos != string::npos)
            {
                string pollEqn = line.substr(dolPos + 1);

                line.erase(dolPos); //remove $eqn

                SCApad(line);

                if (!message.empty())
                {
                    result.push_back(message.erase(message.size() - 1));
                    pollPattern.push_back("");
                    message = "";
                }

                result.push_back(line);
                pollPattern.push_back(pollEqn);

                continue;
            }

            size_t atPos = line.find('@');
            if (atPos != string::npos)
            {
                outVars = line.substr(atPos + 1);
                line.erase(atPos); //remove @OUT_VAR
            }

            if (SCApad(line))
            {
                outputPattern.push_back(outVars); //push_back outvar name, empty string if not present
            }
            message += line + "\n";
        }
    }

    if (!message.empty())
    {
        result.push_back(message.erase(message.size() - 1));
        pollPattern.push_back("");
    }

    return result;
}

void SCA::checkIntegrity(const string& request, const string& response)
{
    string responseTemp = response;
    while (responseTemp.find("svl_connect") != string::npos)
    {
        responseTemp.erase(responseTemp.find("svl_connect"), strlen("svl_connect"));
    }
    for (size_t i = 0; i < responseTemp.size(); i++)
    {
        if (!(isxdigit(responseTemp[i]) || responseTemp[i] == '\n' || responseTemp[i] == ',' || responseTemp[i] == 'x'))
        {
            throw runtime_error("SCA: Invalid character received in RPC data:\n" + response + "\n");
        }
    }

    vector<string> reqVec = Utility::splitString(request, "\n");
    vector<string> resVec = Utility::splitString(response, "\n");

    reqVec.erase(remove(reqVec.begin(), reqVec.end(), "svl_reset"), reqVec.end()); //remove reset's
    reqVec.erase(remove(reqVec.begin(), reqVec.end(), "sc_reset"), reqVec.end()); //remove reset's

    if (reqVec.size() != resVec.size())
    {
        throw runtime_error("SCA: Invalid number of lines received!"); 
    }

    for (size_t i = 0; i < resVec.size(); i++)
    {
        transform(reqVec[i].begin(), reqVec[i].end(), reqVec[i].begin(), ::tolower);
        transform(resVec[i].begin(), resVec[i].end(), resVec[i].begin(), ::tolower);

        if (reqVec[i] == "svl_connect" && resVec[i] == reqVec[i])
        {
            continue;
        }

        vector<string> scaPartsReq = Utility::splitString(reqVec[i], ",");
        vector<string> scaPartsRes = Utility::splitString(resVec[i], ",");
        if (scaPartsReq.size() == 2 && scaPartsRes.size() > 0)
        {
            if (scaPartsReq[1] == "wait" && scaPartsReq[0] == scaPartsRes[0])
            {
                continue;
            }
            else if (scaPartsReq.size() == scaPartsRes.size() && scaPartsReq[0].substr(0, 6) == scaPartsRes[0].substr(0, 6)) //check only CH and TRID
            {
                continue;
            }
        }

        throw runtime_error("SCA: Integrity check of received message failed!");
    }
}

/*
 * Return VARs values (as vector because of the multiplicity) ordered top to bottom as in the sequence 
 */
vector<vector<unsigned long> > SCA::readbackValues(const string& message, const vector<string>& outputPattern, Instructions::Instruction& instructions)
{
    vector<string>& vars = instructions.vars;
    vector<string> splitted = Utility::splitString(message, "\n");

    vector<unsigned long> values;
    for (size_t i = 0; i < splitted.size(); i++)
    {
        size_t pos = splitted[i].find(",");
        if (pos != string::npos)
        {
            values.push_back(stoul(splitted[i].substr(pos + 1), NULL, 16)); //all 32 bits payloads
        }
        else
        {
            values.push_back(0); //because of SCA wait
        }
    }

    vector<vector<unsigned long> > results(vars.size(), vector<unsigned long>());
    for (size_t i = 0; i < values.size(); i++)
    {
        if (outputPattern[i] != "") //if there is a VAR in the request line
        {
            size_t id = distance(vars.begin(), find(vars.begin(), vars.end(), outputPattern[i])); //Order values as VARs
            results[id].push_back(values[i]);
        }
    }

    return results;
}

uint32_t SCA::getReturnWidth()
{
    return SCA_RETURN_WIDTH;
}

#include <cctype>
#include <math.h>
#include <algorithm>
#include <string>
#include <iomanip>
#include <sstream>
#include "Alfred/print.h"
#include "Parser/utility.h"
#include "Fred/Config/instructions.h"
#include "Fred/Protocols/SWT.h"

const string SWT::swtResetWord_v0 = "reset";
const string SWT::swtResetWord_v1 = "sc_reset";

void SWT::SWTpad(string& line)
{
	stringstream ss;

	if (line.length() <= SWT_LOW_WIDTH) ss << "0x" << setw(SWT_LOW_WIDTH) << setfill('0') << hex << line;
	else if (line.length() <= SWT_MIDDLE_WIDTH) ss << "0x" << setw(SWT_MIDDLE_WIDTH) << setfill('0') << hex << line;
	else if (line.length() <= SWT_HIGH_WIDTH) ss << "0x" << setw(SWT_HIGH_WIDTH) << setfill('0') << hex << line;
	else throw runtime_error("SWT " + to_string(SWT_HIGH_WIDTH * 4) + " bits exceeded!"); //check SWT max width

	line = ss.str();
}

vector<string> SWT::generateMessage(Instructions::Instruction& instructions, vector<string>& outputPattern, vector<string>& pollPattern, ProcessMessage* processMessage)
{
	bool parseInVar = instructions.inVars.size() > 0;

	int32_t multiplicity = processMessage->getMultiplicity();
	size_t messageSize = instructions.message.size();

    string swtResetWord = (processMessage->getAlfVersion() == Location::AlfEntry::Version::v0 ? swtResetWord_v0 : swtResetWord_v1) + "\n";

	vector<string> result;
    string message = swtResetWord;

	for (int32_t m = 0; m < multiplicity; m++)
	{
		for (size_t i = 0; i < messageSize; i++)
		{
			string outVar;
			string line = instructions.message[i]; //add raw user line

			if (parseInVar) processMessage->parseInputVariables(line, instructions.inVars, m); //parse invariables

			if (line.find("0x") == 0) line = line.substr(2); //remove eventual "0x"

			size_t dolPos = line.find('$'); //user poll
			if (dolPos != string::npos)
			{
				string pollEqn = line.substr(dolPos + 1);

				line.erase(dolPos); //remove $eqn

				SWTpad(line);
				line += ",write\nread";

				if (!message.empty())
				{
					result.push_back(message.erase(message.size() - 1));
					pollPattern.push_back("");
                    message = swtResetWord;
				}

                result.push_back(swtResetWord + line);
				pollPattern.push_back(pollEqn);

				continue;
			}

			size_t atPos = line.find('@');
			if (atPos != string::npos) //user read @OUT_VAR
			{
				outVar = line.substr(atPos + 1);

				line.erase(atPos); //remove @OUT_VAR

				SWTpad(line);
				line += ",write\nread";

				outputPattern.push_back("");
				outputPattern.push_back(outVar);

			}
            else if (line.find("wait") != string::npos)
            {
                int32_t waitVal = 3;

                vector<string> wait = Utility::splitString(line, ",");
                if (wait.size() == 2)
                {
                    try
                    {
                        waitVal = stoi(wait[0]);
                    }
                    catch (invalid_argument& e)
                    {
                        throw runtime_error("SWT invalid wait value");
                    }

                    if (waitVal <= 0)
                    {
                        throw runtime_error("SWT invalid wait value");
                    }
                }

                line = to_string(waitVal) + ",wait";
                outputPattern.push_back("");
            }
			else //user write
			{
				outputPattern.push_back("");

				SWTpad(line);
				line += ",write";
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

void SWT::checkIntegrity(const string& request, const string& response)
{
	for (size_t i = 0; i < response.size(); i++)
	{
		if (!(isxdigit(response[i]) || response[i] == '\n' || response[i] == 'x'))
		{
			throw runtime_error("SWT: Invalid character received in RPC data:\n" + response + "\n");
		}
	}

	vector<string> reqVec = Utility::splitString(request, "\n");
	vector<string> resVec = Utility::splitString(response, "\n");

    reqVec.erase(remove(reqVec.begin(), reqVec.end(), swtResetWord_v0), reqVec.end()); //remove reset's
    reqVec.erase(remove(reqVec.begin(), reqVec.end(), swtResetWord_v1), reqVec.end()); //remove reset's

	if (reqVec.size() != resVec.size())
	{
		throw runtime_error("SWT: Invalid number of lines received!");
	}

	for (size_t i = 0; i < resVec.size(); i++)
	{
		transform(reqVec[i].begin(), reqVec[i].end(), reqVec[i].begin(), ::tolower);
		transform(resVec[i].begin(), resVec[i].end(), resVec[i].begin(), ::tolower);

        if (reqVec[i].find("wait") != string::npos)
        {
            vector<string> wait = Utility::splitString(reqVec[i], ",");
            if (wait.size() != 2)
            {
                throw runtime_error("SWT: Invalid wait request!");
            }

            if (wait[0] != resVec[i])
            {
                throw runtime_error("SWT: Error on SWT wait operation!");
            }

            continue;
        }

		if (resVec[i].length() != (SWT_HIGH_WIDTH + strlen("0x")) && (resVec[i].length() != strlen("0")))
		{
			throw runtime_error("SWT: Invalid width message received!");
		}

		if ( (reqVec[i].find("write") != string::npos && resVec[i] != "0") || (reqVec[i].find("read") != string::npos && resVec[i] == "0"))
		{
			throw runtime_error("SWT: Integrity check of received message failed!");
		}
	}
}

/*
 * Return VARs values (as vector because of the multiplicity) ordered top to bottom as in the sequence 
 */
vector<vector<unsigned long> > SWT::readbackValues(const string& message, const vector<string>& outputPattern, Instructions::Instruction& instructions)
{
	vector<string>& vars = instructions.vars;
	vector<string> splitted = Utility::splitString(message, "\n");

	vector<unsigned long> values;
	for (size_t i = 0; i < splitted.size(); i++)
	{
		values.push_back(stoul(splitted[i].size() > 4 ? splitted[i].substr(splitted[i].size() - 4) : splitted[i], NULL, 16)); //last 4 or 0
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

uint32_t SWT::getReturnWidth()
{
    return SWT_RETURN_WIDTH;
}

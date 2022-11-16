#ifndef SCA_H
#define SCA_H

#include <vector>
#include <string>
#include "Fred/Config/instructions.h"
#include "Parser/processmessage.h"

using namespace std;

const int SCA_RETURN_WIDTH = 8; //Width of the SCA OUT_VARs

class SCA //: public Protocol
{
public:
    static vector<string> generateMessage(Instructions::Instruction& instructions, vector<string>& outputPattern, vector<string>& pollPattern, ProcessMessage* processMessage);
    static void checkIntegrity(const string& request, const string& response);
    static vector<vector<unsigned long> > readbackValues(const string& message, const vector<string>& outputPattern, Instructions::Instruction& instructions);
    static uint32_t getReturnWidth();
    static string valuesToString(vector<vector<unsigned long> > values, int32_t multiplicity);
    static bool SCApad(string& line);
};

#endif // SCA_H

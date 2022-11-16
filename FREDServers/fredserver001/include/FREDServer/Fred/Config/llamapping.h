#ifndef LLAMAPPING_H
#define LLAMAPPING_H

#include "Fred/Config/location.h"
#include <string>
#include <vector>

using namespace std;

class LlaMapping: public Location
{
public:
    struct LlaEntry
    {
        AlfEntry alfEntry;
        uint32_t repeat, delay;
    };

    LlaMapping(vector<string> data = vector<string>());

    vector<LlaEntry>& alfList();

private:
    void processLlaUnit(const string& line, const string& params = "");
    void processLocation(string alfId, int32_t serialId, uint32_t repeat = 1, uint32_t delay = 0);

    bool checkIfEntryExists(const string& alfId, int32_t serialId);

    vector<LlaEntry> llaEntries;
};

#endif

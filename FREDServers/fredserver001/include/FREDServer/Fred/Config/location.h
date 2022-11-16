#ifndef LOCATION_H
#define LOCATION_H

#include <string>
#include <vector>
#include <map>

#define MAPPING_UNIT_DELIMITER "\t"

using namespace std;

class Location
{
public:
    
    struct AlfEntry
    {
        enum Version
        {
            v0, //without endpoint
            v1 //with endpoint
        };

        struct SerialEntry
        {
            enum CardType
            {
                CRU,
                CRORC
            };

            struct EndpointEntry
            {
                int32_t id; //ENDPOINT_ID
                vector<int32_t> links;
            };

            int32_t id; //SERIAL_ID
            map<int32_t, EndpointEntry> endpoints;
            CardType cardType;
        };

        string id; //ALF_ID
        map<int32_t, SerialEntry> serials;
        Version version;
    };

protected:
    map<string, AlfEntry> alfs;
};

#endif // LOCATION_H

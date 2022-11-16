#ifndef MAPIGROUP_H
#define MAPIGROUP_H

#include <iostream>
#include <string>
#include <algorithm>
#include <vector>
#include "Fred/Mapi/mapi.h"

using namespace std;

class Mapigroup: public Mapi
{
public:
    void newMapiGroupRequest(vector<pair<string, string> > requests);
    void newTopicGroupRequest(vector<pair<string, string> > requests);
};

#endif // MAPIGROUP_H

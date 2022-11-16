/* Uncomment commented lines and recompile to use MAPI example
*/

#include <stdio.h>
#include <fstream>
#include "Fred/fred.h"
//#include "Fred/global.h"
#include "Alfred/print.h"
/*#include "Mapi/mapiexample.h"*/
#include "Mapi/sampa_config.h"

int main(int argc, char** argv)
{
	bool parseOnly = Fred::commandLineArguments(argc, argv);
	//	pair<string, string> config = Fred::readConfigFile();
	Fred fred(parseOnly, Fred::readConfigFile(), "./sections");
	
	std::vector<int> chamblinks {12,12,12,12,38,38,17,17,44,44}; 
	std::vector<int> crulinks;
	std::vector<string> chambers {"1L","2L","3R","4R","7L","7R","8L","8R","10L","10R"};
	
   //ch1L
   
	for (int i=10; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 111; i++){crulinks.emplace_back(i);}
	
	//ch2L
	
	for (int i=112; i <= 123; i++){crulinks.emplace_back(i);}
	//ch3R
	for (int i=30; i <= 35; i++){crulinks.emplace_back(i);}
	for (int i=312; i <= 317; i++){crulinks.emplace_back(i);}
	
	//ch4R
	for (int i=36; i <=  39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 311; i++){crulinks.emplace_back(i);}
	for (int i=318; i <= 323; i++){crulinks.emplace_back(i);}
	
//ch7L
	for (int i=10; i <= 14; i++){crulinks.emplace_back(i);}
	for (int i=112; i <= 123; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 33; i++){crulinks.emplace_back(i);}
	for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 322; i++){crulinks.emplace_back(i);}
//ch7R
	for (int i=10; i <= 14; i++){crulinks.emplace_back(i);}
	for (int i=112; i <= 123; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 33; i++){crulinks.emplace_back(i);}
	for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 322; i++){crulinks.emplace_back(i);}
//ch8L
	for (int i=50; i <= 54; i++){crulinks.emplace_back(i);}
	for (int i=512; i <= 523; i++){crulinks.emplace_back(i);}
	
//ch8R
	for (int i=50; i <= 54; i++){crulinks.emplace_back(i);}
	for (int i=512; i <= 523; i++){crulinks.emplace_back(i);}
	

//ch10L
	for (int i=10; i <= 13; i++){crulinks.emplace_back(i);}
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 122; i++){crulinks.emplace_back(i);}
 for (int i=14; i <= 14; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 310; i++){crulinks.emplace_back(i);}
 for (int i=318; i <= 318; i++){crulinks.emplace_back(i);}
	for (int i=312; i <= 317; i++){crulinks.emplace_back(i);}
 for (int i=319; i <= 322; i++){crulinks.emplace_back(i);}
//ch10R
	for (int i=10; i <= 13; i++){crulinks.emplace_back(i);}
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 122; i++){crulinks.emplace_back(i);}
 for (int i=14; i <= 14; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 310; i++){crulinks.emplace_back(i);}
 for (int i=318; i <= 318; i++){crulinks.emplace_back(i);}
	for (int i=312; i <= 317; i++){crulinks.emplace_back(i);}
 for (int i=319; i <= 322; i++){crulinks.emplace_back(i);}
 

	SampaConfig sampaConfig[crulinks.size()];
	int t = 0;
	try
	{   
		for (int r=0; r < chambers.size(); r++)
		{
			for (int i=1; i <= chamblinks[r]; i++)	
			{
				if (t >= crulinks.size())
				{
					printf("Size of sampa objects greater than size of links: ERROR!");
					return 0;
				}
				fred.registerMapiObject("FRED2/SAMPA_CONFIGCH"+chambers[r]+"/SOLAR"+std::to_string(crulinks[t])+"/SAMPA_REG", &sampaConfig[t]);
				t++;
			}
			
		}
	}

	catch (exception& e)
	{
		exit(EXIT_FAILURE);
	}

	fred.Start();
	return 0;
}


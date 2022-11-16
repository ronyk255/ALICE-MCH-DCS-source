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
	
	std::vector<int> chamblinks {24,12,24,12,21,21,44,44}; 
	std::vector<int> crulinks;
	std::vector<string> chambers {"3L","3R","4L","4R","8L","8R","9R","9L"};
	

//ch3L
	for (int i=10; i <= 15; i++){crulinks.emplace_back(i);}
	for (int i=112; i <= 117; i++){crulinks.emplace_back(i);}
	for (int i=50; i <= 55; i++){crulinks.emplace_back(i);}
	for (int i=512; i <= 517; i++){crulinks.emplace_back(i);}
//ch3R
	
	for (int i=330; i <= 335; i++){crulinks.emplace_back(i);}
	for (int i=3312; i <= 3317; i++){crulinks.emplace_back(i);}
//ch4L
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 111; i++){crulinks.emplace_back(i);}
	for (int i=118; i <= 123; i++){crulinks.emplace_back(i);}
	for (int i=56; i <= 59; i++){crulinks.emplace_back(i);}
	for (int i=510; i <= 511; i++){crulinks.emplace_back(i);}
	for (int i=518; i <= 523; i++){crulinks.emplace_back(i);}
//ch4R
	for (int i=336; i <=  339; i++){crulinks.emplace_back(i);}
	for (int i=3310; i <= 3311; i++){crulinks.emplace_back(i);}
	for (int i=3318; i <= 3323; i++){crulinks.emplace_back(i);}
 
 //ch8L
 
	for (int i=10; i <= 13; i++){crulinks.emplace_back(i);}
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 122; i++){crulinks.emplace_back(i);}
	//ch8R
	
	for (int i=10; i <= 13; i++){crulinks.emplace_back(i);}
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 122; i++){crulinks.emplace_back(i);}
	//ch9R
	for (int i=30; i <= 33; i++){crulinks.emplace_back(i);}
	for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 322; i++){crulinks.emplace_back(i);}
	for (int i=34; i <= 34; i++){crulinks.emplace_back(i);}
	for (int i=50; i <= 59; i++){crulinks.emplace_back(i);}	
	for (int i=510; i <= 510; i++){crulinks.emplace_back(i);}
	for (int i=522; i <= 522; i++){crulinks.emplace_back(i);}		      
	for (int i=512; i <= 521; i++){crulinks.emplace_back(i);}
	//ch9L
	for (int i=30; i <= 33; i++){crulinks.emplace_back(i);}
	for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 322; i++){crulinks.emplace_back(i);}
	for (int i=34; i <= 34; i++){crulinks.emplace_back(i);}
	for (int i=50; i <= 59; i++){crulinks.emplace_back(i);}	
	for (int i=510; i <= 510; i++){crulinks.emplace_back(i);}
	for (int i=522; i <= 522; i++){crulinks.emplace_back(i);}		      
	for (int i=512; i <= 521; i++){crulinks.emplace_back(i);}
	
	
 

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
				fred.registerMapiObject("FRED3/SAMPA_CONFIGCH"+chambers[r]+"/SOLAR"+std::to_string(crulinks[t])+"/SAMPA_REG", &sampaConfig[t]);
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


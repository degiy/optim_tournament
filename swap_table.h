#ifndef SWAP_TABLE_H_
#define SWAP_TABLE_H_

#include "teams_on_slot.h"
#include "board.h"

#include <vector>
using namespace std;

// Table used to swap matches to get a better board at last
// Need to be compact with fast copy. Matches are only keep as teams bit maps
class SwapTable
{
public:
    SwapTable(Board &b,char* a_break,char* spare_slots); // build upon the board (optimized version of board based on vectors instead of linked list)
    SwapTable(SwapTable&); // copy
    void Debug(); // print table
    int ScoreIt(); // score calc
    int BestSwap(int ttl); // recursive simple moves
    void DoSwap(int x, int y,int xx, int yy); // actual swap of matches
        void ParseBreak(char*);
        void ParseSplice(char*,short&,short&);

    vector<TeamsOnSlot> slots; // all teams playing on a slot
    vector<vector<TeamsOnSlot>> table; // big table with all slots and courts (can vary between slots)
    short nb_matches;
    short break_x,break_y,break_n; // if a break is to be added in the tournamend (e.g. lunch time)
};

#endif // SWAP_TABLE_H_

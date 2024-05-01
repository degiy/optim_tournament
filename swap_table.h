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
    SwapTable(Board &b); // build upon the board (optimized version of board based on vectors instead of linked list)
    void Debug(); // print table
    int ScoreIt(); // score calc
    int BestSwap(int ttl); // recursive simple moves
    void DoSwap(int x, int y,int xx, int yy); // actual swap of matches

    vector<TeamsOnSlot> slots; // all teams playing on a slot
    vector<vector<TeamsOnSlot>> table; // big table with all slots and courts (can vary between slots)
    short nb_matches;
};

#endif // SWAP_TABLE_H_

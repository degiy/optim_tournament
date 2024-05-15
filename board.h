#ifndef BOARD_H_
#define BOARD_H_

// big board with all matches
// a match can be in several states
// - in the big general waiting list, waiting to be poll for the current slot (not yet full)
// - in a slot match list (affected)
// - in a wanabee list, as it couldn't fit in the current slot, we schedule it to be tried in the second next
// - in no list, as we fail to find it room in a slot, in this case the programm failed and scoring is 0
//

#include "match_cell.h"
#include "slot.h"

#include <vector>
using std::vector;

class Board
{
    public:
        Board(short nb_slots,short nb_matches);
        void SetNbCourts(short nb_courts); // to set all slots to the same number of availlable courts (capacity)
        void DimSlots(char *file); // load courts nb for each slot from a file
        void ResetMatches(); // to avoid to delete and recreate the board
        void Run(int loops); // do the optim : fill the slots the best way possible
        void CalcMaxSlots(); // calc the number of overall slots (all courts for all time slots)
        void Pass1A(); // first random filling of matches (trying to preserve teams not playing 2 consecutive matches)
        void Pass1B(); // second filling with no random (just based on wanabees slots)
        bool Pass1C(); // 3rd path with less ideal scenatio (fill the holes)
        int  ScoreIt(); // return score of the board
        void NthCell(short skip,MatchCell **prev,MatchCell **curr); // skip n elements in list from head then return previous and current cell address
        void Debug(); // print board for debug purposes
        short PrintListOfCells(MatchCell &head); // print list from head
        MatchCell* EndOfList(MatchCell *head); // return end of list

        vector<MatchCell> cells;
        vector<Slot> slots;
        vector<Slot> wanabees;
        Slot big_list;
        short nb_max_slots;

        static bool random_set;
};

#endif // BOARD_H_

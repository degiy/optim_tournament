#ifndef SLOT_H_
#define SLOT_H_

#include "match_cell.h"
#include "teams_on_slot.h"

class Slot
{
    public:
        Slot();
        Slot(short capa);
        bool TryInsert(MatchCell &prev, MatchCell &curr); // try to insert a match
        short TryInsert2(MatchCell &prev, MatchCell &curr, TeamsOnSlot &prev_tos); // try to insert a match with constraint on previous slot
        void Insert(MatchCell &prev, MatchCell &curr); // insert a match (wanabees)
        void PrintSlot(); // for debug purpose

        MatchCell head; // index for first match of the slot
        short capacity; // number of matches possible on the slot (maximum playable)
        short nb; // actual number of matches already slotted
        short id; // id of slot (for information)
        TeamsOnSlot teams; // to know which team is already on the slot
};

#endif // SLOT_H_

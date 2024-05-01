#ifndef TEAMS_ON_SLOT_H_
#define TEAMS_ON_SLOT_H_

#include "common.h"
#include <bitset>

class TeamsOnSlot : public std::bitset<MAX_TEAMS>
{
    public:
        TeamsOnSlot();
        TeamsOnSlot(TeamId);
        TeamsOnSlot(TeamId,TeamId);
        bool TstMatch(TeamId,TeamId); // check wether one of the team is already playing on this slot
        void AddMatch(TeamId,TeamId); // add both team as playing on the slot
        void Debug(); // print slot

                static void CapToNbTeams(int nb); // to display only the number of teams and no more
                static int cap;
};

#endif // TEAMS_ON_SLOT_H_

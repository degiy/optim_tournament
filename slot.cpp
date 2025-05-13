#include "slot.h"
#include "common.h"
#include "match_cell.h"
#include "teams_on_slot.h"

Slot::Slot() : nb{0}, capacity{MAX_SLOTS}, id{-1}
{
}


Slot::Slot(short capa) : nb{0}, capacity{capa}
{
    teams.reset();
}

void Slot::PrintSlot()
{
    printf("  %02hd=> nb(%hd) capa(%hd) tos(%d) : ",id,nb,capacity,teams.count());
}

bool Slot::TryInsert(MatchCell &prev, MatchCell &curr)
{
    bool ret=false;
    if (teams.TstMatch(curr.a, curr.b))
    {
        teams.AddMatch(curr.a,curr.b);
        short curr_id=prev.next;
        prev.next=curr.next; // remove match from initial list
        curr.next=head.next;
        head.next=curr_id; // we insert curr at begining of chained list
        nb++;
        ret=true;
    }
    return ret;
}

// force insertion (for wanabee slots or is checks are made before)
void Slot::Insert(MatchCell &prev, MatchCell &curr)
{
    teams.AddMatch(curr.a,curr.b);
    short curr_id=prev.next;
    prev.next=curr.next; // remove match from initial list
    curr.next=head.next;
    head.next=curr_id; // we insert curr at begining of chained list
    nb++;
}

short Slot::TryInsert2(MatchCell &prev, MatchCell &curr, TeamsOnSlot &prev_tos)
{
    // default return value (next next slot)
    short ret;
    // calculate a single tos made by our match
    TeamsOnSlot match(curr.a,curr.b);
    // calculate both collision with current slot and previous one
    std::bitset<MAX_TEAMS> col_cur=match&teams;
    int ccc=col_cur.count();
    std::bitset<MAX_TEAMS> col_prev=match&prev_tos;
    int ccp=col_prev.count();
    if (ccc>0)
    {
        // at least one team already playing this slot, so we need to try not before slot n+2
        ret=2;
    }
    else if (ccp==0)
    {
        // neither team played the slot before => good
        // nor for the current slot (we can insert)
        Insert(prev,curr);
        ret=0;
    }
    else
    {
        // neither team played the current slot, but at least one of them did on previous one
        // we can try the match on next slot
        ret=1;
    }
    return ret;
}

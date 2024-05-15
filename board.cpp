#include "board.h"
#include "common.h"
#include "match_cell.h"
#include "teams_on_slot.h"

#include <bitset>
#include <cstdlib>
#include <ctime>
#include <iostream>

bool Board::random_set {false};

Board::Board(short nb_slots, short nb_matches) : cells(nb_matches), slots(nb_slots), wanabees(nb_slots+2)
{
    ResetMatches();
    if (random_set==false)
    {
        srand(std::time(nullptr)); // init randomness
        random_set=true;
    }
}

void Board::SetNbCourts(short nb_courts)
{
    for (short i=0;i<slots.size();i++)
    {
        slots[i].capacity=nb_courts;
    }
}

void Board::DimSlots(char *file)
{
    FILE *fd = fopen(file, "r");
    int nbc;
    short i=0;

    // Check if the file opened successfully
    if (fd == NULL)
    {
        printf("Error opening file %s to read matches from.\n",file);
        throw 1;
    }
    // count nb of slots in file
    while(fscanf(fd,"%d",&nbc)!=EOF) i++;
    slots.resize(i);
    wanabees.resize(i+2);
    ResetMatches();
    i=0;
    // Read and print integers from the file until the end
    fseek(fd,0,SEEK_SET);
    while (fscanf(fd, "%d", &nbc) != EOF)
    {
        slots[i++].capacity=nbc;
    }
   fclose(fd);
}

void Board::ResetMatches()
{
    // reset linked list
    // of matches and clean slots
    short i;
    big_list.id=-1;       // not used
    big_list.capacity=0;  // not used
    big_list.nb=cells.size();// just for debug
    big_list.teams.reset();  // no meaning here
    big_list.head.next=0;
    for (i=0;i<cells.size()-1;i++)
    {
        cells[i].next=i+1;
    }
    cells[cells.size()-1].next=-1; // so the big list if full with all cells (matches)

    i=0;
    for (auto& it: slots)
    {
        it.id=i++;          // id shoud not change
        it.nb=0;            // reset list
        it.teams.reset();   // no team still plaing
        it.head.next=-1;    // empty list
    }
    i=0;
    for (auto& it: wanabees)
    {
        it.id=i++;
        it.capacity=0;      // no meaning for wanabees
        it.nb=0;            // reset list
        it.teams.reset();   // no meaning as we could have the same team playing twice
        it.head.next=-1;    // empty list
    }
}

void Board::CalcMaxSlots()
{
    nb_max_slots=0;
    for (auto& it: slots)
    {
        nb_max_slots+=it.capacity;
    }
}

void Board::Run(int loops)
{
    // best board to keep
    Board best_board(slots.size(),cells.size());
    int run=0;
    int best_score=0;
    int score;
    while(run++<loops)
    {
        Pass1A();
        Pass1B();
        if(Pass1C()==false)
        {
            score=0;
            if (verbose>2) printf("Pass1C failed to place all matches\n");
        }
        else
        {
            score=ScoreIt();
            if (score>best_score)
            {
                if (verbose>1) printf("    new best score at run %d : %d\n",run,score);
                best_score=score;
                best_board=*this;
                if (verbose>1) best_board.Debug();
            }
        }
        ResetMatches();
        if (debug>5)
        {
            printf("-- after ResetMatches --\n");
            Debug();
        }
    }
    *this=best_board;
}

void Board::NthCell(short skip,MatchCell **prev,MatchCell **curr)
{
    *prev=&(big_list.head);
    while(skip-->0)
    {
        *prev=&(cells[(*prev)->next]);
    }
   *curr=&(cells[(*prev)->next]);
}

void Board::Pass1A()
{
    short remain=cells.size();
    // sanity check
    if (remain>nb_max_slots)
    {
        printf("Big problem : you give me less slots (%hd) than matches to play (%hd)\n",nb_max_slots,remain);
        throw 1;
    }
    short sl_nb=0;
    TeamsOnSlot sl_minus1;
    int skip;
    while(remain>0)
    {
        // let's take a random match and try to place it on a time slot
        skip= rand()%remain;
        MatchCell *pr,*cu;
        NthCell(skip,&pr,&cu);
        short rk=slots[sl_nb].TryInsert2(*pr,*cu,sl_minus1);
        if (rk==0)
        {
            // no match for any of both team on the present time slot, so we succeed in moving the match to the linked list of current slot
            // check if we finished all the holes of current time slot
            if (slots[sl_nb].nb==slots[sl_nb].capacity)
            {
                // no more, so jump to next one
                if (debug>3) printf("  end of slot %hu\n",sl_nb);
                sl_minus1=slots[sl_nb].teams;
                sl_nb++;
            }
        }
        else
        {
            // ok maybe next time (depending on rank)
            wanabees[sl_nb+rk].Insert(*pr,*cu);
        }
        remain--;
        big_list.nb--; // for debug
        if (verbose>4)
        {
            printf(" pass1A random try %hu (skip %d) on slot %hu :\n",cells.size()-remain,skip,sl_nb);
            Debug();
        }
    }
    if (verbose>3)
    {
        printf("end of pass1A on slot %hu\n",sl_nb) ;
        Debug();
    }
}

MatchCell* Board::EndOfList(MatchCell *head)
{
    while (head->next>=0)
        head=&(cells[head->next]);

    return head;
}

void Board::Pass1B()
{
    // wanabees management
    for(short i=1;i<slots.size();i++)
    {
      TeamsOnSlot &sl_minus1=slots[i-1].teams;
      while (wanabees[i].nb > 0)
      {
        MatchCell *pr=&(wanabees[i].head);
        MatchCell *cu=&(cells[pr->next]);
        if (slots[i].nb == slots[i].capacity)
        {
            // no more, so we move the rest of wanabees of slot n to slot n+1
            MatchCell *pend=EndOfList(&(wanabees[i+1].head));
            pend->next=pr->next;
            pr->next=-1;
            wanabees[i+1].nb+=wanabees[i].nb;
            wanabees[i].nb=0;
        }
        else
        {
            short rk = slots[i].TryInsert2(*pr, *cu, sl_minus1);
            if (rk != 0)
            {
                // ok maybe next time (depending on rank)
                wanabees[i + rk].Insert(*pr, *cu);
            }
            wanabees[i].nb--;
        }
      }
      if (debug > 3)
      {
          printf(" pass1B rk %h :\n",i);
          Debug();
      }
    }
}

bool Board::Pass1C()
{
    // last wanabees (n+1,n+2) management : they didn't idealy fit, so lets fill the holes
    short is=0;
    short is2;
    for(short iw=slots.size();iw<wanabees.size();iw++)
    {
        // fast forward to the first slot with room
        while (slots[is].nb>=slots[is].capacity)
        {
            is++;
            if (is>=slots.size()) break;
        }

        while (wanabees[iw].nb > 0)
        {
            // worst case : no more slots availlable, but still matches (normally not possible)
            if (is>=slots.size())
                return false;
            MatchCell *pr=&(wanabees[iw].head);
            MatchCell *cu=&(cells[pr->next]);
            for(is2=is;is2<slots.size();is2++)
            {
                if(slots[is2].nb<slots[is2].capacity)
                {
                    if(slots[is2].TryInsert(*pr,*cu))
                    {
                        is2=slots.size()+1; // no exit for loop
                        wanabees[iw].nb--;
                    }
                }
            }
            if (is2==slots.size())
            {
                // we didn't manage to place this match...
                if (debug > 3)
                    Debug();
                if (verbose > 2)
                    printf("pass1C : failed on [%hhu,%hhu]\n",cu->a,cu->b);
                return false;
            }
        }
    }
    if (debug > 3)
        Debug();
    if (verbose > 2)
        printf("pass1C : ok\n");
    return true;
}

int Board::ScoreIt()
{
    int score=cells.size(); // initial score
    std::bitset<MAX_TEAMS> last_tos=slots[0].teams;
    // substract counter for each 2 consecutive match of each team
    for(int i=1;i<slots.size();i++)
    {
        std::bitset<MAX_TEAMS> cur_tos=slots[i].teams;
        score-=(last_tos&cur_tos).count();
        last_tos=cur_tos;
    }
    // substract one more is 3 consecutive matches
    std::bitset<MAX_TEAMS> lastt_tos=slots[0].teams;
    last_tos=slots[1].teams;
    for(int i=2;i<slots.size();i++)
    {
        std::bitset<MAX_TEAMS> cur_tos=slots[i].teams;
        std::bitset<MAX_TEAMS> tos=lastt_tos&last_tos&cur_tos;
        score-=tos.count();
        lastt_tos=last_tos;
        last_tos=cur_tos;
    }
    return score;
}

short Board::PrintListOfCells(MatchCell &head)
{
    MatchCell *p=&head;
    short cp=0;
    while (p->next>=0)
    {
        p=&(cells[p->next]);
        printf("[%hhu,%hhu] ",p->a,p->b);
        cp++;
    }
    printf(": total %hd\n",cp);
    return cp;
}

void Board::Debug()
{
    printf("Debug Board :\n\n- nb_matches=%ld\n- nb_max_slots=%hd\n- big list :\n",cells.size(),nb_max_slots);
    big_list.PrintSlot();
    PrintListOfCells(big_list.head);
    printf("\n- slots :\n");
    short cp=0;
    for(auto& it: slots)
    {
        it.PrintSlot();
        cp+=PrintListOfCells(it.head);
    }
    printf("  => %hd entries\n\n- wanabees :\n",cp);
    cp=0;
    for(auto& it: wanabees)
    {
        it.PrintSlot();
        cp+=PrintListOfCells(it.head);
    }
    printf("  => %hd entries\n",cp);
}

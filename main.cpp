#include "swap_table.h"
#include "teams_on_slot.h"
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <argp.h>
#include <string.h>

using namespace std;

#include "board.h"
#include "swap_table.h"

Board *main_board=nullptr;
SwapTable *main_table=nullptr;

short verbose=0;
short debug=0;

const char *argp_program_version = "optim 0.1";
const char *argp_program_bug_address = "<jerome_jansou@yahoo.fr>";
static char doc[] = "optim : a tool to fill the best tournament schedule";

/* A description of the arguments we accept. */
static char args_doc[] = "<matches_input_file.csv>";

/* The options we understand. */
static struct argp_option options[] = {
    {"debug", 'd', 0, 0, "Increase debug level"},
    {"verbose", 'v', 0, 0, "Increase verbose level"},
    {"runs", 'r', "NB", 0, "How many random draws of match orders we try to find the best initial score in phase 1 (default = 1000)"},
    {"recurse", 'R', "NB", 0, "How much recursion on each optimization phase (aka phase 2) you want on swaping matches (default = 2)"},
    {"optims", 'z', "NB", 0, "Maximum consecutive optimization phases (or phases 2) to try, as long as scoring increases (default = 2)"},
    {"overall", 'O', "NB", 0, "Overall number of successive runs of phases 1 and 2 (default = 2)"},
    {"nb-slots", 's', "NB", 0, "How many time slots we envision for the tournament"},
    {"nb-courts", 'c', "NB", 0, "How many courts/playgrounds we can use for the tournament"},
    {"nb-teams", 't', "NB", 0, "To cap the maximum number of teams, for debug purpose only"},
    {"tune-courts", 'T', 0, 0, "Tune the placement of each team on each court to limit moves (will try every permutation possible)"},
    {"break", 'b', "N,X,Y", 0, "Each teams need a lunch break of N consecutive slots, between slot X and slot Y (syntax : N,X,Y). Will need optimizer."},
    {"inject-empty-slots", 'i', "N,X", 0, "splice current slots to insert N empty slots at index X by end of phase 1 to ease phase 2 job to void a break for all teams"},
    {"slots", 'S', "FILE", 0, "Input slot file to load to populate the number of courts per time slot"},
    {"out", 'o', "FILE", 0, "Output file (tournament result file from optimizer)"},
    {0}};

/* Used by main to communicate with parse_opt. */
struct arguments
{
    int verbose, debug, nb_runs, recurse, nb_slots, nb_courts, max_optim,overall,tune_courts;
    char *output_file, *input_file, *break_syntax, *slot_file, *injection_syntax;
};

/* Parse a single option. */
static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
    /* Get the input argument from argp_parse, which we know is a pointer to our arguments structure. */
    struct arguments *arguments = (struct arguments *)state->input;

    switch (key)
    {
        case 'd':
            arguments->debug++;
            break;
        case 'v':
            arguments->verbose++;
            break;
        case 'T':
            arguments->tune_courts++;
            break;
        case 'r':
            arguments->nb_runs= atoi(arg);
            break;
        case 'R':
            arguments->recurse= atoi(arg);
            break;
        case 's':
            arguments->nb_slots = atoi(arg);
            break;
        case 'c':
            arguments->nb_courts = atoi(arg);
            break;
        case 'z':
            arguments->max_optim = atoi(arg);
            break;
        case 'O':
            arguments->overall = atoi(arg);
            break;
        case 'o':
            arguments->output_file = arg;
            break;
        case 'b':
            arguments->break_syntax = arg;
            break;
        case 'i':
            arguments->injection_syntax = arg;
            break;
        case 't':
            TeamsOnSlot::CapToNbTeams(atoi(arg));
            break;
        case 'S':
            arguments->slot_file=arg;
            break;
        case ARGP_KEY_ARG:
            // arguments
            arguments->input_file=arg;
            break;
        case ARGP_KEY_END:
            break;
        default:
            return ARGP_ERR_UNKNOWN;
    }
    return 0;
}

/* argp parser. */
static struct argp argp = {options, parse_opt, args_doc, doc};
struct arguments arguments;

int main(int argc, char *argv[])
{
    FILE *file;
    TeamId t1, t2;
    short nb_matches;

    /* Default values for all arguments */
    memset((void *)&arguments, 0, sizeof(arguments));
    // except for a few
    arguments.nb_runs=1000;
    arguments.recurse=2;
    arguments.max_optim=2;
    arguments.overall=2;

    /* Parse our arguments; every option seen by parse_opt will be reflected in arguments. */
    argp_parse(&argp, argc, argv, 0, 0, &arguments);

    // Verbose + Debug
    verbose=arguments.verbose;
    debug=arguments.debug;

    // Number of slots
    short nb_slots=arguments.nb_slots;
    // Number of courts
    short nb_courts=arguments.nb_courts;

    // Open the file of matches
    file = fopen(arguments.input_file, "r");

    // Check if the file opened successfully
    if (file == NULL)
    {
        printf("Error opening file %s to read matches from.\n",arguments.input_file);
        return 1;
    }
    // Read and print integers from the file until the end
    while (fscanf(file, "%hhu %hhu", &t1, &t2) != EOF)
    {
        nb_matches++;
    }
    fseek(file,0,SEEK_SET);
    main_board=new Board(nb_slots,nb_matches);
    // check if a slot file was provided
    if (arguments.slot_file)
    {
       main_board->DimSlots(arguments.slot_file);
    }
    else
    {
        main_board->SetNbCourts(nb_courts);
    }
    main_board->CalcMaxSlots();
    short i=0;
    while (fscanf(file, "%hhu %hhu", &t1, &t2) != EOF)
    {
        main_board->cells[i].a=t1;
        main_board->cells[i].b=t2;
        i++;
    }
    // Close the file
    fclose(file);
    vector<SwapTable*> oo_table(arguments.overall);
    int oo_bs=0;
    int oo_bt=0;
    for(int oo=0;oo<arguments.overall;oo++)
    {
        printf("- overall run %d\n",oo+1);
        main_board->Run(arguments.nb_runs);

        main_table=new SwapTable(*main_board,arguments.break_syntax,arguments.injection_syntax);
        oo_table[oo]=main_table;
        int score1=main_table->ScoreIt();
        int best_score=score1;
        printf("  - Initial score (after phase 1): %d\n",score1);
        if (debug) main_table->Debug();
        for(int ttl=arguments.max_optim;ttl>0;ttl--)
        {
            int score=main_table->BestSwap(arguments.recurse);
            if (score>best_score)
            {
                printf("  - new best score from a phase 2 : %d\n",main_table->ScoreIt());
                if (debug) main_table->Debug();
                best_score=score;
                if (score>oo_bs)
                {
                    oo_bs=score;
                    oo_bt=oo;
                    printf("    and best overall score !\n");
                }
            }
            else ttl=0; // no need to continue as we didn't make better than previous score
        }
        if (best_score==score1)
        {
            // phase 2 didn't bring something new to the table, we stay on phase 1
            printf("  x phase 2 couldn't make better\n");
            if (score1>oo_bs)
            {
                oo_bs=score1;
                oo_bt=oo;
                printf("    but best overall score anyway so far\n");
            }
        }
    }
    // print the best table
    printf("Best score is %d for board :\n",oo_bs);
    oo_table[oo_bt]->Debug();
    // tune courts ?
    if (arguments.tune_courts)
    {
        oo_table[oo_bt]->OptimCourts();
        printf("Best court optimisation for teams :\n");
        oo_table[oo_bt]->Debug();
    }

    return 0;
}

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <argp.h>
#include <string.h>

using namespace std;

#include "board.h"

Board *main_board=nullptr;

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
    {"runs", 'r', "NB", 0, "How many random draws of match orders we try to find the best initial score (default = 1000)"},
    {"nb-slots", 's', "NB", 0, "How many time slots we envision for the tournament"},
    {"nb-courts", 'c', "NB", 0, "How many courts/playgrounds we can use for the tournament"},
    {"optim", 'z', 0, 0, "Run the swap optimizer on the tournament with the best initial score"},
    {"break", 'b', "N,X,Y", 0, "Each teams need a lunch break of N consecutive slots, between slot X and slot Y (syntax : N,X,Y). Will need optimizer."},
    {"out", 'o', "FILE", 0, "Output file (tournament result file from optimizer)"},
    {0}};

/* Used by main to communicate with parse_opt. */
struct arguments
{
    int verbose, debug, nb_runs, nb_slots, nb_courts, flag_optim;
    char *output_file, *input_file, *break_syntax;
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
        case 'r':
            arguments->nb_runs= atoi(arg);
            break;
        case 's':
            arguments->nb_slots = atoi(arg);
            break;
        case 'c':
            arguments->nb_courts = atoi(arg);
            break;
        case 'z':
            arguments->flag_optim = 1;
            break;
        case 'o':
            arguments->output_file = arg;
            break;
        case 'b':
            arguments->break_syntax = arg;
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
    main_board->SetNbCourts(nb_courts);
    main_board->CalcMaxSlots();
    short i=0;
    while (fscanf(file, "%hhu %hhu", &t1, &t2) != EOF)
    {
        main_board->cells[i].a=t1;
        main_board->cells[i].b=t2;
        i++;
    }
    main_board->Run(arguments.nb_runs);

    // Close the file
    fclose(file);

    return 0;
}

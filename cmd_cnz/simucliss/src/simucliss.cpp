//======================================================================
//
// NAME
//      simucliss.cpp
//
// COPYRIGHT
//      Ericsson AB 2014 - All rights reserved
//
//      The Copyright to the computer program(s) herein is the property of Ericsson AB, Sweden.
//      The program(s) may be used and/or copied only with the written permission from Ericsson
//      AB or in accordance with the terms and conditions stipulated in the agreement/contract
//      under which the program(s) have been supplied.
//
// DESCRIPTION
//      -
//
// DOCUMENT NO
//      -
//
// AUTHOR
//      2014-01-28 by ESTEVOL
// CHANGES
//	Wed Oct 28 2020 Dharma Theja
//		Added fix for HY57850
//      Thu Dec 17 2015 Boddu Thirupathi
//              Added is_node_active function for fixing TR HU38973
//      Mon Dec 03 2018 Neelam kumar
//		Adapted changes according to SWM 2.0 for fixing TR HX36566
//========================================================================

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <setjmp.h>
#include <termios.h>
#include <time.h>

#include <string.h>
extern int errno;

typedef void (*sighandler_t)(int);
//static
static bool restricted = true;
sigjmp_buf ctrlc_buf;
sigjmp_buf quit_buf;
struct termios saved_attributes;

#define COM_PROMPT "\03>"
#define COMMAND_NOT_FOUND "ERROR: Command not found or not allowed in Restricted AP session.\n"
#define COMMAND_USAGE "ERROR: Incorrect usage\n"
#define GOD_MODE_ENABLED false
//#define ARRAY_SIZE(array) (sizeof(array)/sizeof(array[0]))

#define ACTIVE_NODE 1
#define PASSIVE_NODE 2

#define SIZE 1
#define NUMELEM 20

#define APPLICATION_NAME "simucliss"
#define INPUTRC_PATH "/opt/ap/apos/conf/simucliss.conf"
#define CMD_OPTIONS "b"

static const char* commands[] = {
        "mml",
        "exit",
        "help",
        "history",
        (const char *)NULL
};


void handle_signal(int/* signo*/)
{
	printf("\n");
	rl_free_line_state();
	fflush(stdout);
	siglongjmp(ctrlc_buf, 1);
}

void handle_termination(int/* signo*/)
{
	siglongjmp(quit_buf, 1);
}

char** fill_argv(char *tmp_argv)
{
	int index = 0;
	int count = 0;
	char *ptr = tmp_argv;
	char* prev_ptr = ptr;
	while((ptr = strchr(ptr, ' ')) != 0) {

		if(ptr != prev_ptr)
			count++;
		prev_ptr = ++ptr;
	}
	count++;

	char** my_argv = new char*[count+1]();

	char* pch = strtok (tmp_argv," ");
	while (pch != NULL)
	{
		my_argv[index] = new char[(strlen(pch) + 1)];
		memset(my_argv[index], 0, (strlen(pch)+1)*sizeof(char));
		sprintf (my_argv[index],"%s",pch);
		pch = strtok (NULL, " ");
		index++;
	}

	return my_argv;
}

char** copy_envp(char **envp)
{
	char **my_envp = 0;
	int length = 0;
	for (length = 0; envp[length];length++);

	int index = 0;
	my_envp = new char*[length + 1];
	memset(my_envp,0,(length+1)*sizeof(char*));

	for(index = 0; envp[index] != 0; index++) {
		my_envp[index] = new char[(strlen(envp[index]) + 1)];
		memset(my_envp[index], 0, (strlen(envp[index]) + 1)* sizeof(char));
		memcpy(my_envp[index], envp[index], (strlen(envp[index])*sizeof(char)));
	}

	my_envp[index] = 0;

	return my_envp;

}

char* get_path_string(char **tmp_envp)
{
	int count = 0;
	char *tmp = 0;
	char *bin_path = 0;
	bool found = false;

	while(tmp_envp[count] && !found) {
		tmp = strstr(tmp_envp[count], "PATH");
		if(tmp == NULL || tmp != (tmp_envp[count])) {
			count++;
		} else {
			found = true;
		}
	}

	if (found)
	{
		bin_path = new char[strlen(tmp)+1];
		memset(bin_path,0,(strlen(tmp)+1)*sizeof(char));
		memcpy(bin_path, tmp, strlen(tmp)*sizeof(char));
	}

	return bin_path;

}

char** insert_path_str_to_search(char *path_str)
{
	int index = 0;
	char *tmp = path_str;
	char **search_path = 0;

	tmp = strchr(tmp, '=');
	tmp++;

	int count = 0;
	char *ptr = tmp;
	while((ptr = strchr(ptr, ':')) != 0) {
	    count++;
	    ptr++;
	}

	if (count)
	{
		count++;
		search_path = new char*[count+1]();

		char* pch = strtok (tmp,":");
		while (pch != NULL)
		{
			search_path[index] = new char[(strlen(pch) + 2)]();
			sprintf (search_path[index],"%s/",pch);
			pch = strtok (NULL, ":");
			index++;
		}

	}

	return search_path;
}

char* attach_path(char *cmd, char **search_path)
{

	int index;
	int fd;
	char* full_path = 0;
	int len_base = strlen(cmd);

	for(index=0; search_path[index] != NULL; index++) {
		int len = len_base + strlen(search_path[index]) + 1;
		full_path = new char[len]();
		memcpy(full_path, search_path[index], strlen(search_path[index]) * sizeof(char));
		strncat(full_path, cmd, strlen(cmd));

		if((fd = open(full_path, O_RDONLY)) > 0)
		{
			close(fd);
			return full_path;
		}
		else
		{
			delete[] full_path;
			full_path = 0;
		}
	}
	return full_path;
}

void call_execve(char *cmd, char** my_argv, char** my_envp)
{
	int i;
	signal(SIGINT, SIG_IGN);
	signal(SIGTSTP, SIG_IGN);
	if(fork() == 0) {
		i = execve(cmd, my_argv, my_envp);
		if(i < 0) {
			//printf("%s: %s\n", cmd, "command not found");
			printf(COMMAND_NOT_FOUND);
			exit(1);
		}
		else
			exit(0);
	} else {
		wait(NULL);
	}
}

void free_argv(char** &my_argv)
{
	int index;
	if (my_argv)
	{
		for(index=0; my_argv[index] != 0; index++) {
			//memset(my_argv[index], 0, strlen(my_argv[index])+1);
			delete[] my_argv[index];
			my_argv[index] = 0;
		}

		delete[] my_argv;
		my_argv = 0;
	}
}

char *duplicate_str(const char *s)
{
	char *r = (char *)malloc(sizeof(char)* (strlen(s) + 1));
	memset(r,0,(strlen(s) + 1)*sizeof(char));
	memcpy(r, s, strlen(s)*sizeof(char));
	return r;
}
const char* skip_leadingspace(const char* text)
{

	int b = 0;
	// skipping leading spaces
	while (text[b] && isspace(text[b])){
		++b;
	}
	return (text + b);
}
char* auto_complete(const char* text, int state)
{
        const char *name = 0;

        /* If this is a new word to complete, initialize now.  This
                    includes saving the length of TEXT for efficiency, and
                    initializing the index variable to 0. */
	
        const char *str = skip_leadingspace(text);
        int cmd_index = state;
        int len = strlen(str);
        //int white_spaces = strlen(text) - len;
	
        /* Return the next name which partially matches from the
            command list. */
        while ((name = commands[cmd_index])) {
        	cmd_index++;
        	int temp_len = strlen(name);

        	if (strncmp(name, str, len) == 0)
        	{
        		if(temp_len == len)
        			return (char *)0;
        		return duplicate_str(name);
        	}
        }

        //list_index = 0;
        return (char *) 0;           /* No names matched. */
}


char **command_completion (const char *text, int /*start*/, int /*end*/)
{
     char **matches;
     matches = (char **)NULL;

     /* If this word is at the start of the line, then it is a command
     to complete. Otherwise completion is over. */
     matches = rl_completion_matches (text, auto_complete);
     if(!matches) rl_attempted_completion_over = 1;
	

    /* if (start == 0)
     {
    	 matches = rl_completion_matches (text, auto_complete);
    	 if(!matches) rl_attempted_completion_over = 1;
     }
     else
     {
    	 rl_attempted_completion_over = 1;
     }*/
	return (matches);

}

void printhelp()
{
	if (restricted)
		printf("This is a Restricted AP session.\n\n"
				"The following key bindings and commands are supported.\n\n"
				"KEY BINDINGS\n\n"
				"arrow keys           Up and down arrow keys recall commands previously entered.\n"
				"                     Left and right arrow keys move through the text on the command line.\n"
				"tab                  When tab is pressed at any position of a command, a completion\n"
				"                     request is interactively done on all possible continuations of the command.\n"
				"                     Example:\n"
				"                     >h[TAB] # command name discovery\n"
				"                     help\n"
				"                     helloWorldCommand\n"
				"                     >helloWorldCommand # command execution\n"
				"                     Hello World\n"
				"                     >\n\n"
				"GENERAL COMMANDS\n\n"
				"exit                 Quit CLI session.\n"
				"help                 Display this introduction help.\n"
				"history              Display the command history of the current session.\n\n"
				"SPECIFIC COMMANDS\n\n"
				"<command>            Execute the specific command named <command>.\n\n");
	else
		printf("Unrestricted AP Session. All commands are allowed.\n");
}

void printhistory()
{
	register HIST_ENTRY **the_list;
	register int i;

	the_list = history_list();

	char size[32] = {0};
	sprintf(size,"%d",history_length);
	int width = strlen(size);

	if (the_list)
	{
		for (i = 0; the_list[i] && (i < history_length); i++)
		{
			printf ("%*d %s %s\n", width, i + history_base, the_list[i]->timestamp, the_list[i]->line);
		}
	}
}

void validate_cmd(char** my_argv, char** my_envp, char **search_path)
{
	int fd;
	char* cmd = my_argv[0];

	if (strcmp(cmd,"help") == 0)
	{
		if(my_argv[1] != NULL)
		{
			printf(COMMAND_USAGE);
		}
		else
		{
			printhelp();
		}
	}
#if GOD_MODE_ENABLED
	else if (strcmp(cmd,"godmode") == 0)
		restricted = false;
#endif
	else if (strcmp(cmd,"history") == 0)
	{
		if(my_argv[1] != NULL)
		{
			printf(COMMAND_USAGE);
		}
		else
		{
			printhistory();
		}
	}
	else if (!restricted || (restricted && strcmp(cmd,"mml") == 0))
	{
		if(strchr(cmd, '/') == NULL)
		{
			char* full_cmd = attach_path(cmd, search_path);
			if(full_cmd)
			{
				call_execve(full_cmd, my_argv, my_envp);
				delete[] full_cmd;
			}
			else
			{
				printf(COMMAND_NOT_FOUND);
			}
		}
		else
		{
			if((fd = open(cmd, O_RDONLY)) > 0) {
				close(fd);
				call_execve(cmd, my_argv, my_envp);
			} else {
				printf(COMMAND_NOT_FOUND);
			}
		}
	}
	else
	{
		printf(COMMAND_NOT_FOUND);
	}
}
void checkparam(int argc, char* argv[] )
{
	bool printmesg = true  ;
	int option = 0;
 	opterr=0;	
	int opt_flag = false;
	if(argc > 2)
	{
	 printf("Illegal Option %s\n",argv[1]);
	 exit(0);
	}
	if(argc > 1)
	{
		while((option = getopt(argc, argv,CMD_OPTIONS))!=-1)
		{	
			switch (option) {
			case 'b' :
				printmesg = false;
				opt_flag = true;
				break;
			case '?':
			case ':':
			default :
				printf("Illegal Option %s\n",argv[1]);
				exit(0);
			}
		}

		if((option==-1) && (opt_flag ==false))
		{
			printf("Illegal Option %s\n",argv[1]);
			exit(0);
		}	
	}
	if(printmesg)
	{
		printf("RESTRICTED AP SESSION\n\n");
		//printf(">");
		fflush(stdout);
	}

}

void restore_terminal (void)
{
	tcsetattr (STDIN_FILENO, TCSANOW, &saved_attributes);
//	clear_history();
}

void internal_error(const char* err_msg)
{
	printf("Internal error: %s\n",err_msg);
	exit(1);
}

/**********************************************************************************

           bool is_Node_Role_Active()
           Return value -- true  indicates Active node
                           false indicates Passive node

**********************************************************************************/
bool is_Node_Role_Active()
{

	FILE *fp1;
	int node_Id;//indicates node Id
        int node_Role;//indicates node active or passive
        char buff[512];
        size_t bytes_read;

	fp1 = fopen("/etc/cluster/nodes/this/id","r");

	if (fp1 == NULL)
	{
		printf("Internal Error: Failed to check active or passive node\n" );
                exit(0);
	}

        memset(buff,0,sizeof(buff));

        bytes_read = fread(buff,SIZE,NUMELEM,fp1);

        if (bytes_read == 0)
        {
                printf("Internal Error: Failed to check active or passive node\n" );
                exit(1);
        }

	node_Id=atoi(buff);

        fclose(fp1);

        FILE *fp2;
        char result[512];

	//Building the command to get HA agent status to know node active or passive
	char command1[]="immlist -a saAmfSISUHAState \"safSISU=safSu=SC-";
	char command2[]="\\\\,safSg=2N\\\\,safApp=ERIC-apg.nbi.aggregation.service,safSi=apg.nbi.aggregation.service-2N-1,safApp=ERIC-apg.nbi.aggregation.service\"";
	char command3[]=" 2>/dev/null| /bin/awk '{print substr($0,length,1)}'";
	char final_command[250];

	snprintf(final_command,sizeof(final_command),"%s%d%s%s",command1,node_Id,command2,command3);

	fp2 = popen(final_command,"r");
        
	if (fp2 == NULL)
	{
		printf("Internal Error: Failed to check active or passive node\n" );
		exit(0);
	}

	if (fgets(result, sizeof(result)-1, fp2) != NULL)
	{
		node_Role=atoi(result);
	}
	else
		node_Role=PASSIVE_NODE;

	pclose(fp2);

	if(node_Role == ACTIVE_NODE )
		return true;//Node is Active
	else
		return false;//Node is Passive 
}


int main(int argc, char *argv[], char *envp[])
{
	int i;
	char *tmp = 0;
	const char *htmp = 0;
	char *path_str = 0;
	char **my_argv = 0;
	char **my_envp = 0;
	char **search_path = 0;

        bool is_node_active = true;
	bool m_exit = false;
	bool m_free_arg = false;

	rl_readline_name = APPLICATION_NAME;
	rl_read_init_file(INPUTRC_PATH);
	using_history();
	stifle_history(100);

	/* Tell the completer that we want a crack first. */
	rl_attempted_completion_function = command_completion;
	rl_completion_append_character = '\0';
	rl_completer_word_break_characters = (char *) "\t";
	
	signal(SIGINT, SIG_IGN);
	signal(SIGINT, handle_signal);
	signal(SIGTSTP, handle_signal);
	signal(SIGQUIT, handle_termination);

        //Check if Node is Active or Passive
        is_node_active = is_Node_Role_Active();

        //If node is passive exit the session else continue
        if (!is_node_active)
        {
                printf("Connection to RESTRICTED AP SESSION failed. (Connection refused)\n" );
                exit(1);
        }

	checkparam(argc,argv);

	//Copy all environment variables
	if (!(my_envp = copy_envp(envp)))
		internal_error("Unable to get environment variables");

	//Get PATH variable...
	if (!(path_str = get_path_string(my_envp)))
		internal_error("Unable to get PATH variable");

	//...and split it.
	if (!(search_path = insert_path_str_to_search(path_str)))
		internal_error("Unable to convert PATH variable");

	tcgetattr(STDIN_FILENO, &saved_attributes);
	atexit(restore_terminal);

	while(sigsetjmp( ctrlc_buf, 1 ) != 0 )
	{
		free_argv(my_argv);
		if (tmp)
			free(tmp);
	}

	if (sigsetjmp( quit_buf, 1 )!= 0)
	{
		m_exit = true;
		m_free_arg = true;
	}

	while(!m_exit) {
		signal(SIGINT,handle_signal);
		signal(SIGTSTP, handle_signal);
		signal(SIGQUIT, handle_termination);	
	
		if (!(tmp = readline(COM_PROMPT)))
		{
			rl_set_prompt("");
			rl_complete_internal('?');
//			rl_set_prompt(COM_PROMPT);
		}
		if (tmp && *tmp)
		{

			htmp=skip_leadingspace(tmp);
			if((strlen(htmp))!=0)
			{
			::add_history(htmp);
			time_t t = time(NULL);

			char buff[20] = {0};
			strftime(buff, 20, "%Y-%m-%d %H:%M:%S", localtime(&t));

			::add_history_time(buff);
			}
		}

		if(tmp && (tmp[0] != '\0'))
		{
			my_argv = fill_argv(tmp);

			if (my_argv[0])
			{
				if(strcmp(my_argv[0],"exit") == 0)
				{
					if(my_argv[1] != NULL)
					{
						printf(COMMAND_USAGE);
					}
					else
					{
						m_exit = true;
						free_argv(my_argv);
						break;
					}
				}
				else
				{
					validate_cmd(my_argv, my_envp, search_path);
					restore_terminal();
				}

			}
			free_argv(my_argv);

		}

		if(tmp == NULL)
                {
                        m_exit = true;
                        m_free_arg = true;
                }

		if(tmp) free(tmp);
		tmp = 0;

	}

	if(m_free_arg)
		free_argv(my_argv);

	if (tmp)
		free(tmp);

	if (my_envp)
	{
		for(i=0; my_envp[i] != 0; i++)
		{
			delete[] my_envp[i];
			my_envp[i] = 0;
		}

		delete []my_envp;
	}

	if (search_path)
	{
		for(i=0; search_path[i] != NULL; i++)

		{
			delete[] search_path[i];
			search_path[i] = 0;
		}

		delete[] search_path;
	}

	printf("\n");
	clear_history();
	return 0;
}

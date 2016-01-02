/*
 * cli.c
 *
 * $Id: cli.c,v 1.4 2005/03/10 14:07:05 brad Exp $
 */

#define printf xprintf

#define NULL 0
#define MAX_LINE 256
#define MAX_ARGV 32

#define CLI_PROMPT "diag> "

int argc;
char *argv[MAX_ARGV];

static char line[MAX_LINE];
static char line2[MAX_LINE];

int cmd_help(int argc, char *argv[]);

int cmd_tled(int argc, char *argv[]);
int cmd_tcpld(int argc, char *argv[]);
int cmd_tcpld_int(int argc, char *argv[]);
int cmd_tbuzz(int argc, char *argv[]);

int cmd_aac(int argc, char *argv[]);
int cmd_buzz(int argc, char *argv[]);
int cmd_eeprom(int argc, char *argv[]);
int cmd_pcmcia(int argc, char *argv[]);
int cmd_cclock(int argc, char *argv[]);
int cmd_expbrd(int argc, char *argv[]);
int cmd_cs89(int argc, char *argv[]);
int cmd_cf(int argc, char *argv[]);
int cmd_cpld(int argc, char *argv[]);
int cmd_lcd(int argc, char *argv[]);
int cmd_cache(int argc, char *argv[]);
int cmd_gpio(int argc, char *argv[]);

int cmd_read(int argc, char *argv[]);
int cmd_write(int argc, char *argv[]);
int cmd_dump(int argc, char *argv[]);
int cmd_poke(int argc, char *argv[]);
int cmd_info(int argc, char *argv[]);
int cmd_verbose(int argc, char *argv[]);
int cmd_stop(int argc, char *argv[]);
int cmd_touch(int argc, char *argv[]);
int cmd_memory_test(int argc, char *argv[]);
int cmd_memory_alias_test(int argc, char *argv[]);
int cmd_memory_size_test(int argc, char *argv[]);
int cmd_switches(int argc, char *argv[]);
int cmd_serial(int argc, char *argv[]);

int cmd_tftp(int argc, char *argv[]);

int
cmd_test(int argc, char *argv[])
{
    if (argc < 2) {
        printf("test { cpld | led }\n");
        return -1;
    }

    if (strcmp(argv[1], "cpld") == 0)
	    return cmd_tcpld(argc, argv);

    if (strcmp(argv[1], "led") == 0)
	    return cmd_tled(argc, argv);

    /* cpld interrupt path */
    if (strcmp(argv[1], "int") == 0)
	    return cmd_tcpld_int(argc, argv);

    /* buzzer output */
    if (strcmp(argv[1], "buzz") == 0)
	    return cmd_tbuzz(argc, argv);

    return -1;
}

struct {
    char *cmd;
    int (*func)(int, char **);
    char *desc;
} commands[] = {
	{ "d", cmd_dump, "dump memory as bytes" },
	{ "dw", cmd_dump, "dump memory as 16 bit words" },
	{ "dl", cmd_dump, "dump memory as 32 bit words" },
	{ "pb", cmd_poke, "poke memory as byte" },
	{ "pw", cmd_poke, "poke memory as 16 bit word" },
	{ "p", cmd_poke, "poke memory as 32 bit long" },
	{ "r", cmd_read, "repetitive read" },
	{ "w", cmd_write, "repetitive write" },
	{ "info", cmd_info, "print cpu info" },
	{ "mt", cmd_memory_test, "run memory test" },
	{ "ma", cmd_memory_alias_test, "run memory alias test" },
	{ "ms", cmd_memory_size_test, "run memory size test" },
	{ "verbose", cmd_verbose, "set verbose mode" },
	{ "stop", cmd_stop, "set stop-on-error mode" },

	{ "ac97", cmd_aac, "control ac97" },
	{ "buzz", cmd_buzz, "control buzzer" },
	{ "eeprom", cmd_eeprom, "read and write cs8900 eeprom" },
	{ "expbrd", cmd_expbrd, "control expbrd control register" },
	{ "cache", cmd_cache, "set cache state" },
	{ "cf", cmd_cf, "control CF ide" },
	{ "clock", cmd_cclock, "set cpu clock speed" },
	{ "cpld", cmd_cpld, "control CPLD" },
	{ "cs89", cmd_cs89, "control expbrd cs8900" },
	{ "gpio", cmd_gpio, "control gpios" },
	{ "lcd", cmd_lcd, "control LCD" },
	{ "pcmcia", cmd_pcmcia, "control pcmcia" },
	{ "serial", cmd_serial, "test serial ports" },
	{ "switch", cmd_switches, "get switch status" },
	{ "test", cmd_test, "test component" },
	{ "tftp", cmd_tftp, "tftp image into ram" },
	{ "touch", cmd_touch, "test touch switch" },
	{ "?", cmd_help, "print help" },
	{ "help", cmd_help, "print help" },
	{ 0 }
};

int
cmd_help(int argc, char *argv[])
{
    int i;

    printf("available commands:\n");
    for (i = 0; commands[i].cmd; i++) {
        printf("%s\t%s\n", commands[i].cmd, commands[i].desc);
    }
}

/*
 * find the first word of the input in the command list and run the
 * command function...
 */
int
parse_command(void)
{
    int i, hit;

    hit = 0;
    for (i = 0; commands[i].cmd; i++) {
        if (strncasecmp(commands[i].cmd, argv[0],
                        strlen(argv[0])) == 0)
        {
            hit++;
            (*commands[i].func)(argc, argv);
            break;
        }
    }

    if (!hit) {
	    printf("unknown command? '%s'\n\r", argv[0]);
    }

    return 0;
}

/*
 * parse new input line, finding word boundaries and creating
 * an argv vector
 */
int
create_argv(void)
{
    char *p, c, t;

    if (0) printf("create_argv() line '%s'\n", line);

    strcpy(line2, line);

    p = line2;
    argc = 0;

    while (*p) {
        if (argc == MAX_ARGV) {
            printf("input exceeds max # of args (%d)", MAX_ARGV);
            printf("'%s'\n", line);
            break;
        }

        /* save start of word */
        argv[argc++] = p;
        argv[argc] = NULL;

        /* quoted string? */
        if (*p == '\'' || *p == '\"') {
            t = *p;

            /* adjust pointer to skip over starting quote */
            argv[argc-1]++;
            p++;

            while (c = *p) {
                if (c == t) {
                    *p++ = 0;
                    break;
                }
                p++;
            }
        } else {
            /* not quoted string, find end of word */
            while (c = *p) {

                if (c == ' ' || c == '\t') {
                    *p++ = 0;
                    break;
                }

                p++;
            }
        }

        /* skip over whitespace */
        while (c = *p) {
            if (c != ' ' && c != '\t')
                break;

            p++;
            continue;
        }
    }

    return 0;
}

void
prompt(void)
{
	printf("\n" CLI_PROMPT);
}

int
cli(void)
{
	while (1) {
		prompt();

		if (readline(line, sizeof(line)))
			continue;

		if (line[0] == 0)
			continue;

		if (create_argv())
			continue;

		parse_command();
	}
}

int
cli_init()
{
	readline_init();
	return 0;
}


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/

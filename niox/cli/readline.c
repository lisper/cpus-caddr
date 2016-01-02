/*
 * readline.c
 *
 * simple 'readline' line editing with basic history
 */

#include "diag.h"

#define printf xprintf

#define MAX_READLINE 256

static char line[MAX_READLINE];
static int line_len;
static int cursor;
static int insert_mode;

static char clipboard[MAX_READLINE];

#define MAX_HISTORY 1024
static char history[MAX_HISTORY];
static int hist_ptr;
static int hist_cursor;
static int hist_count;

static int debug;

static void
beep(void)
{
    putchar(7);
}

#define DEL	0x7f
#define BS	0x08
#define FS	0x1c

static inline void
backspace(void)
{
    putchar('\b');
}

static inline void
backspace_over(void)
{
    printf("\b \b");
}

static void
erase_line(void)
{
    int i;
    for (i = cursor; i < line_len; i++)
        putchar(line[i]);
    for (i = 0; i < line_len; i++)
        backspace_over();
}

static void
erase_to_eol(void)
{
    int i;
    for (i = cursor; i < line_len; i++)
        putchar(' ');
    for (i = cursor; i < line_len; i++)
        backspace();
}

static void
display_line(void)
{
    int i;
    for (i = 0; i < line_len; i++)
        putchar(line[i]);
    for (i = line_len; i > cursor; i--)
        backspace();
}

static void
display_to_eol(void)
{
    int i;
    for (i = cursor; i < line_len; i++)
        putchar(line[i]);
    for (i = line_len; i > cursor; i--)
        backspace();
}

void
readline_history_prev(void)
{
    int i, p;

    if (debug)
        printf("readline_history_prev() hist_count %d, hist_cursor %d\n",
               hist_count, hist_cursor);

    if (hist_cursor == 0) {
        beep();
        return;
    }

    erase_line();

    p = hist_ptr;
    for (i = hist_count; i >= hist_cursor; i--) {
        p--;
        while (history[p-1] && p > 0) p--;
    }

    strcpy(line, &history[p]);
    line_len = cursor = strlen(line);
    display_line();
    hist_cursor--;
}

void
readline_history_next()
{
    int i, p;

    if (debug)
        printf("readline_history_next() hist_count %d, hist_cursor %d\n",
               hist_count, hist_cursor);

    if (hist_cursor >= hist_count-1) {
        beep();
        return;
    }

    erase_line();

    p = 0;
    for (i = 0; i <= hist_cursor; i++) {
        p += strlen(&history[p]) + 1;
    }

    strcpy(line, &history[p]);
    line_len = cursor = strlen(line);
    display_line();
    hist_cursor++;
}

void
readline_history_save(char *line)
{
    int l = strlen(line);

    while (hist_ptr + l + 1 > MAX_HISTORY) {
        int l2 = strlen(history) + 1;
        memcpy(history, &history[l2], MAX_HISTORY-l2);
        hist_ptr -= l2;
        hist_count--;
        if (hist_cursor > 0)
            hist_cursor--;
    }

    strcpy(&history[hist_ptr], line);
    hist_ptr += l + 1;
    hist_count++;
    hist_cursor++;

hist_cursor = hist_count;

    if (debug)
        printf("readline_history_save() hist_count %d, hist_cursor %d\n",
               hist_count, hist_cursor);
}

void
readline_history_show(void)
{
    int n, p;

    n = 1;
    for (p = 0; p < hist_ptr;) {
        printf("%d: %s\r\n", n, &history[p]);
        p += strlen(&history[p]) + 1;
        n++;
    }
}

void
cut(void)
{
    strcpy(clipboard, &line[cursor]);
    erase_to_eol();
    line_len = cursor;
    line[line_len] = 0;
}

void
yank(void)
{
    erase_to_eol();
    strcpy(&line[cursor], clipboard);
    line_len = strlen(line);
    display_to_eol();
}

int
readline(char *buffer, int max_bytes)
{
	int ch, i;

        if (max_bytes > MAX_READLINE)
            max_bytes = MAX_READLINE;

        line_len = 0;
        cursor = 0;
        line[0] = 0;

#define CTRL(c)	((c) - '@')

        while (1) {
            ch = getchar();
            switch (ch) {
            case '\n':
            case '\r':
                line[line_len] = 0;
                strcpy(buffer, line);
                printf("\r\n");
                readline_history_save(line);
                return 0;
                break;

            case '\b': /* backward delete */
            case DEL:
                if (line_len == 0 || cursor == 0) {
                    beep();
                    continue;
                }
                if (cursor == line_len) {
                    backspace_over();
                    line_len--;
                    cursor--;
                    continue;
                }

                for (i = cursor-1; i < line_len; i++) {
                    line[i] = line[i+1];
                    putchar(line[i]);
                }
                for (i = cursor-1; i < line_len; i++)
                    backspace();
                cursor--;
                line_len--;

                break;

            case 'R'-'@': /* redraw line */
                erase_line();
                display_line();
                break;

            case 'U'-'@':
                erase_line();
                line_len = cursor = 0;
                break;

            case 'A'-'@': /* start of line */
                while (cursor > 0) {
                    backspace();
                    cursor--;
                }
                break;

            case 'D'-'@': /* forward delete */
                if (line_len == 0) {
                    beep();
                    continue;
                }
                for (i = cursor; i < line_len; i++) {
                    line[i] = line[i+1];
                    putchar(line[i]);
                }
                putchar(' ');
                for (i = cursor; i < line_len; i++)
                    backspace();
                line_len--;
                line[line_len] = 0;
                break;

            case 'E'-'@': /* end of line */
                while (cursor < line_len) {
                    putchar(line[cursor++]);
                }
                break;

            case 'B'-'@': /* back one char */
                if (cursor == 0) {
                    beep();
                    continue;
                }
                cursor--;
                backspace();
                break;

            case 'F'-'@': /* forward one char */
                if (cursor == line_len) {
                    beep();
                    continue;
                }
                putchar(line[cursor]);
                cursor++;
                break;

            case 'K'-'@':
                cut();
                break;

            case 'Y'-'@':
                yank();
                break;

            case 'P'-'@':
                readline_history_prev();
                break;
            case 'N'-'@':
                readline_history_next();
                break;

            default:
                if (line_len >= max_bytes) {
                    beep();
                } else {
                    if (' ' <= ch && ch <= '~')
                        putchar(ch);
                    else {
                        if (0) printf("[0x%x]", ch);
                        beep();
                        continue;
                    }

                    if (!insert_mode) {
                        line[cursor++] = ch;
                        if (cursor > line_len)
                            line_len = cursor;
                    } else {
                        for (i = line_len; i >= cursor; i--)
                            line[i+1] = line[i];
                        line_len++;
                        line[cursor++] = ch;
                        if (cursor > line_len)
                            line_len = cursor;
                        display_to_eol();
                    }
                }
            }
        }
}

void
readline_init(void)
{
    line_len = 0;
    cursor = 0;
    line[0] = 0;

    insert_mode = 1;
    debug = 0;
    clipboard[0] = 0;

    hist_ptr = 0;
    hist_count = 0;
    hist_cursor = 0;

}

#ifdef TESTME
#include <termios.h>
main()
{
    char l[256];
    struct termios save, new;

    tcgetattr(0, &save);
    new = save;
    cfmakeraw(&new);
    tcsetattr(0, TCSAFLUSH, &new);

    readline_init();
//    debug = 1;
    while (1) {
        if (readline(l, sizeof(l)))
            break;
        printf("l: '%s'\r\n", l);
        readline_history_show();
        if (l[0] == 0 || l[0] == 'q')
            break;
    }

    tcsetattr(0, TCSAFLUSH, &save);
    exit(0);
}

#endif


/*
 * Local Variables:
 * indent-tabs-mode:nil
 * c-basic-offset:4
 * End:
*/

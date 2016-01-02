#include <stdio.h>

#define LM_K_BREAK	0167
#define LM_K_CLEAR_INPUT0110
#define LM_K_CALL	0107
#define LM_K_TERMINAL	0040
#define LM_K_MACRO	0100
#define LM_K_HELP	0116
#define LM_K_RUBOUT	0023
#define LM_K_OVERSTRIKE	0160
#define LM_K_TAB	0022
#define LM_K_LINE	0036
#define LM_K_DELETE	0157
#define LM_K_PAGE	0050
#define LM_K_CLEAR_SCREEN 0050
#define LM_K_RETURN	0136
#define LM_K_QUOTE	0120
#define LM_K_HOLD_OUTPUT0030
#define LM_K_STOP_OUTPUT0170
#define LM_K_ABORT	0067
#define LM_K_RESUME	0047
#define LM_K_STATUS	0046
#define LM_K_END	0156
#define LM_K_ROMAN_I	0101
#define LM_K_ROMAN_II	0001
#define LM_K_ROMAN_III	0102
#define LM_K_ROMAN_IV	0002
#define LM_K_HAND_UP	0106
#define LM_K_HAND_DOWN	0176
#define LM_K_HAND_LEFT	0117
#define LM_K_HAND_RIGHT	0017
#define LM_K_SYSTEM	0141
#define LM_K_NETWORK	0042;

#define LM_SH_LEFT_SHIFT 	0024
#define LM_SH_LEFT_GREEK 	0044
#define LM_SH_LEFT_TOP 0104
#define LM_SH_LEFT_CONTROL	0020
#define LM_SH_LEFT_META 0045
#define LM_SH_LEFT_SUPER	0005
#define LM_SH_LEFT_HYPER	0145
#define LM_SH_RIGHT_SHIFT	0025
#define LM_SH_RIGHT_GREEK	0035
#define LM_SH_RIGHT_TOP 0155
#define LM_SH_RIGHT_CONTROL	0026
#define LM_SH_RIGHT_META	0165
#define LM_SH_RIGHT_SUPER	0065
#define LM_SH_RIGHT_HYPER	0175
#define LM_SH_CAPSLOCK 0125
#define LM_SH_ALTLOCK 0015
#define LM_SH_MODELOCK		0003

int map[256];

main()
{   
	int i, j, data;
	for (i = 0; i < 256; i++) {
		switch (i) {

		case LM_SH_LEFT_SHIFT: data=' '; break;	/* left shift */
		case LM_SH_RIGHT_SHIFT: data=' '; break;	/* right shift */
		case LM_SH_LEFT_CONTROL: data=' '; break;	/* left ctrl */
		case LM_SH_RIGHT_CONTROL: data=' '; break;	/* right ctrl */
		case LM_SH_CAPSLOCK: data=' '; break;	/* caps lock */
       
		case LM_K_RUBOUT: data=0x7f; break;	/* backspace -> rubout */
		case LM_K_RETURN: data='\r'; break;	/* enter -> return */

		case LM_K_TAB: data='\t'; break;	/* TAB */

		case 0123: data='a'; break;	/* A */
		case 0114: data='b'; break;	/* B */
		case 0164: data='c'; break;	/* C */
		case 0163: data='d'; break;	/* D */
		case 0162: data='e'; break;	/* E */
		case 0013: data='f'; break;	/* F */
		case 0113: data='g'; break;	/* G */
		case 0053: data='g'; break;	/* H */
		case 0032: data='i'; break;	/* I */
		case 0153: data='j'; break;	/* J */
		case 0033: data='k'; break;	/* K */
		case 0073: data='l'; break;	/* L */
		case 0154: data='m'; break;	/* M */
		case 0054: data='n'; break;	/* N */
		case 0072: data='o'; break;	/* O */
		case 0172: data='p'; break;	/* P */
		case 0122: data='q'; break;	/* Q */
		case 0012: data='r'; break;	/* R */
		case 0063: data='s'; break;	/* S */
		case 0112: data='t'; break;	/* T */
		case 0152: data='u'; break;	/* U */
		case 0014: data='v'; break;	/* V */
		case 0062: data='w'; break;	/* W */
		case 0064: data='x'; break;	/* X */
		case 0052: data='y'; break;	/* Y */
		case 0124: data='z'; break;	/* Z */

		case 0171: data='0'; break;	/* 0 */
		case 0121: data='1'; break;	/* 1 */
		case 0061: data='2'; break;	/* 2 */
		case 0161: data='3'; break;	/* 3 */
		case 0011: data='4'; break;	/* 4 */
		case 0111: data='5'; break;	/* 5 */
		case 0051: data='6'; break;	/* 6 */
		case 0151: data='7'; break;	/* 7 */
		case 0031: data='8'; break;	/* 8 */
		case 0071: data='9'; break;	/* 9 */

		case 0077: data='`'; break;	/* ` */
		case 0131: data='-'; break;	/* - */
		case 0126: data='='; break;	/* = */
		case 0037: data='\\'; break;	/* \ */
		case 0132: data='['; break;	/* [ */

		case 0137: data=']'; break;	/* ] */
		case 0173: data=':'; break;	/* : */
		case 0133: data='\''; break;	/* ' */
		case 0034: data=','; break;	/* , */
		case 0074: data='.'; break;	/* . */
		case 0174: data='/'; break;	/* / */

		case 0134: data=' '; break;	/* space */

		default:   data=  0; break;	/* All other keys are undefined */
		}

		map[i] = data;
	}

	for (i = 0; i < 128; i += 8) {
		for (j = 0; j < 8; j++)
			printf("0x%02x%s", map[i+j], j == 7 ? "" : ", ");
		printf("\n");
	}
}


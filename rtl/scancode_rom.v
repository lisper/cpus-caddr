// scancode_rom.v

//
// map pc-at ps/2 keyboard scancodes (raw) to lispm scancodes
//

module scancode_rom(addr, data);

   input [8:0] addr;
   output reg [7:0] data;

   parameter [7:0]
		LM_K_BREAK	= 8'o167,
		LM_K_CLEAR_INPUT= 8'o110,
		LM_K_CALL	= 8'o107,
		LM_K_TERMINAL	= 8'o040,
		LM_K_MACRO	= 8'o100,
		LM_K_HELP	= 8'o116,
		LM_K_RUBOUT	= 8'o023,
		LM_K_OVERSTRIKE	= 8'o160,
		LM_K_TAB	= 8'o022,
		LM_K_LINE	= 8'o036,
		LM_K_DELETE	= 8'o157,
		LM_K_PAGE	= 8'o050,
		LM_K_CLEAR_SCREEN=8'o050,
		LM_K_RETURN	= 8'o136,
		LM_K_QUOTE	= 8'o120,
		LM_K_HOLD_OUTPUT= 8'o030,
		LM_K_STOP_OUTPUT= 8'o170,
		LM_K_ABORT	= 8'o067,
		LM_K_RESUME	= 8'o047,
		LM_K_STATUS	= 8'o046,
		LM_K_END	= 8'o156,
		LM_K_ROMAN_I	= 8'o101,
		LM_K_ROMAN_II	= 8'o001,
		LM_K_ROMAN_III	= 8'o102,
		LM_K_ROMAN_IV	= 8'o002,
		LM_K_HAND_UP	= 8'o106,
		LM_K_HAND_DOWN	= 8'o176,
		LM_K_HAND_LEFT	= 8'o117,
		LM_K_HAND_RIGHT	= 8'o017,
		LM_K_SYSTEM	= 8'o141,
		LM_K_NETWORK	= 8'o042;

   parameter [7:0]
		LM_SH_LEFT_SHIFT 	= 8'o024,
		LM_SH_LEFT_GREEK 	= 8'o044,
		LM_SH_LEFT_TOP		= 8'o104,
		LM_SH_LEFT_CONTROL	= 8'o020,
		LM_SH_LEFT_META		= 8'o045,
		LM_SH_LEFT_SUPER	= 8'o005,
		LM_SH_LEFT_HYPER	= 8'o145,
		LM_SH_RIGHT_SHIFT	= 8'o025,
		LM_SH_RIGHT_GREEK	= 8'o035,
		LM_SH_RIGHT_TOP		= 8'o155,
		LM_SH_RIGHT_CONTROL	= 8'o026,
		LM_SH_RIGHT_META	= 8'o165,
		LM_SH_RIGHT_SUPER	= 8'o065,
		LM_SH_RIGHT_HYPER	= 8'o175,
		LM_SH_CAPSLOCK		= 8'o125,
		LM_SH_ALTLOCK		= 8'o015,
		LM_SH_MODELOCK		= 8'o003;
   
   always @addr   
     case (addr)

       9'h012: data <= LM_SH_LEFT_SHIFT;	/* left shift */
       9'h059: data <= LM_SH_RIGHT_SHIFT;	/* right shift */
       9'h11f: data <= LM_SH_LEFT_TOP;
       9'h127: data <= LM_SH_RIGHT_TOP;
       9'h014: data <= LM_SH_LEFT_CONTROL;	/* left ctrl */
       9'h114: data <= LM_SH_RIGHT_CONTROL;	/* right ctrl */
// left meta 0200
// right meta 0100
       9'h011: data <= LM_SH_LEFT_META;		/* left alt */
       9'h111: data <= LM_SH_RIGHT_META;	/* right alt */
// left sl 0080
// right sl 0040
       9'h058: data <= LM_SH_CAPSLOCK;	/* caps lock */
       
       9'h005: data <= LM_K_TERMINAL;	/* F1 -> terminal */
       9'h006: data <= LM_K_SYSTEM;	/* F2 -> system */
       9'h004: data <= LM_K_NETWORK;	/* F3 -> network */
       9'h00c: data <= LM_K_ABORT;	/* F4 -> abort */
       9'h003: data <= LM_K_CLEAR_INPUT;/* F5 -> clear input */
       9'h00b: data <= LM_K_HELP;	/* F6 -> help */
       9'h083: data <= LM_K_CLEAR_SCREEN;/* F7 -> clear screen */
       9'h007: data <= LM_K_BREAK;	/* F12 -> break */

       9'h16c: data <= LM_K_CALL;	/* home -> call */
       9'h169: data <= LM_K_END;	/* end -> end */
       9'h17d: data <= LM_K_BREAK;	/* pg up -> break */
       9'h17a: data <= LM_K_BREAK;	/* pg dn -> resume */

//E1,14,
//e1,77,
//E1,F0,14,
//F0,77
//       : data <= LM_K_BREAK; /* break -> break */

       9'h170: data <= LM_K_ABORT;	/* insert -> abort */
       9'h171: data <= LM_K_OVERSTRIKE;	/* delete -> overstrike */

       9'h076: data <= LM_K_TERMINAL;   /* esc -> terminal */
       9'h175: data <= LM_K_HAND_UP;    /* up -> */
       9'h172: data <= LM_K_HAND_DOWN;  /* down -> */
       9'h16b: data <= LM_K_HAND_LEFT;  /* left -> */
       9'h174: data <= LM_K_HAND_RIGHT; /* right -> */

       9'h066: data <= LM_K_RUBOUT;	/* backspace -> rubout */
       9'h05a: data <= LM_K_RETURN;	/* enter -> return */

       9'h00d: data <= LM_K_TAB;	/* TAB */

       9'h01c: data <= 8'o123;	/* A */
       9'h032: data <= 8'o114;	/* B */
       9'h021: data <= 8'o164;	/* C */
       9'h023: data <= 8'o163;	/* D */
       9'h024: data <= 8'o162;	/* E */
       9'h02b: data <= 8'o013;	/* F */
       9'h034: data <= 8'o113;	/* G */
       9'h033: data <= 8'o053;	/* H */
       9'h043: data <= 8'o032;	/* I */
       9'h03b: data <= 8'o153;	/* J */
       9'h042: data <= 8'o033;	/* K */
       9'h04b: data <= 8'o073;	/* L */
       9'h03a: data <= 8'o154;	/* M */
       9'h031: data <= 8'o054;	/* N */
       9'h044: data <= 8'o072;	/* O */
       9'h04d: data <= 8'o172;	/* P */
       9'h015: data <= 8'o122;	/* Q */
       9'h02d: data <= 8'o012;	/* R */
       9'h01b: data <= 8'o063;	/* S */
       9'h02c: data <= 8'o112;	/* T */
       9'h03c: data <= 8'o152;	/* U */
       9'h02a: data <= 8'o014;	/* V */
       9'h01d: data <= 8'o062;	/* W */
       9'h022: data <= 8'o064;	/* X */
       9'h035: data <= 8'o052;	/* Y */
       9'h01a: data <= 8'o124;	/* Z */

       9'h045: data <= 8'o171;	/* 0 */
       9'h016: data <= 8'o121;	/* 1 */
       9'h01e: data <= 8'o061;	/* 2 */
       9'h026: data <= 8'o161;	/* 3 */
       9'h025: data <= 8'o011;	/* 4 */
       9'h02e: data <= 8'o111;	/* 5 */
       9'h036: data <= 8'o051;	/* 6 */
       9'h03d: data <= 8'o151;	/* 7 */
       9'h03e: data <= 8'o031;	/* 8 */
       9'h046: data <= 8'o071;	/* 9 */

       9'h00e: data <= 8'o077;	/* ` */
       9'h04e: data <= 8'o131;	/* - */
       9'h055: data <= 8'o126;	/* = */
       9'h05d: data <= 8'o037;	/* \ */
       9'h054: data <= 8'o132;	/* [ */

       9'h05b: data <= 8'o137;	/* ] */
       9'h04c: data <= 8'o173;	/* ; */
       9'h052: data <= 8'o133;	/* ' */
       9'h041: data <= 8'o034;	/* , */
       9'h049: data <= 8'o074;	/* . */
       9'h04a: data <= 8'o174;	/* / */

       9'h029: data <= 8'o134; /* space */

       default: data <=  0;	/* All other keys are undefined */
     endcase
endmodule


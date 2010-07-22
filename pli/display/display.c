#ifdef _WIN32
#include "SDL.h"
#else
#include <SDL/SDL.h>
#endif

#include <vpi_user.h>

//#include <cv.h>
//#include <highgui.h>

//#define MAX_DSPY 8

static SDL_Surface *screen;
static int rows, cols;
//static IplImage *img_sink;
static unsigned int row_sink, col_sink;

static int cv_init_display_calltf(char*c)
{
  vpiHandle sys_tf_ref, arg_iter;
  vpiHandle rows_h, cols_h;
  s_vpi_value value;
  int flags;

  sys_tf_ref = vpi_handle(vpiSysTfCall, NULL);
  arg_iter = vpi_iterate(vpiArgument, sys_tf_ref);
  
  value.format = vpiIntVal;

  cols_h = vpi_scan(arg_iter);
  vpi_get_value(cols_h, &value);
  cols = value.value.integer;

  rows_h = vpi_scan(arg_iter);
  vpi_get_value(rows_h, &value);
  rows = value.value.integer;

  vpi_printf("Initialize display %dx%d\n", cols, rows);


  flags = SDL_INIT_VIDEO | SDL_INIT_NOPARACHUTE;

  if (SDL_Init(flags)) {
	  vpi_printf("SDL initialization failed\n");
	  return -1;
  }

  flags = SDL_HWSURFACE|SDL_ASYNCBLIT|SDL_HWACCEL;

  screen = SDL_SetVideoMode(cols, rows, 8, flags);

  if (!screen) {
	  vpi_printf("Could not open SDL display\n");
	  return -1;
  }

  SDL_WM_SetCaption("Image", "Image");

  row_sink = col_sink = 0;

  return 0;
}


static int eol;
static int eof;

static int cv_clk_display_calltf(char*c)
{
  unsigned char *ps;
  vpiHandle sys_tf_ref, arg_iter;
  vpiHandle vact_h, hact_h, din_h;
  s_vpi_value value;

  sys_tf_ref = vpi_handle(vpiSysTfCall, NULL);
  arg_iter = vpi_iterate(vpiArgument, sys_tf_ref);
  
  value.format = vpiIntVal;
  
  if(screen == NULL) {
    vpi_printf("Error: display not initialized\n");
    return -1;
  }

  vact_h = vpi_scan(arg_iter);
  vpi_get_value(vact_h, &value);
  
  if(value.value.integer == 0) {
    if(eof) {
      eof = 0;
      vpi_printf("Frame Complete\n");
//      cvShowImage("Image",img);
//      cvWaitKey(0);
    }
    row_sink = col_sink = 0;
    eol = 0;
    return 0;
  }

  hact_h = vpi_scan(arg_iter);
  vpi_get_value(hact_h, &value);
  if(value.value.integer == 0) {
    if(eol == 1){
      row_sink++;
    }
    eol = 0;
    col_sink = 0;
    return 0;
  }

  din_h = vpi_scan(arg_iter);
  vpi_get_value(din_h, &value);
  
  /* do it */
  ps = screen->pixels;
  ps[ (row_sink * cols) + col_sink ] = (unsigned char)value.value.integer;

  SDL_UpdateRect(screen, col_sink, row_sink, 1, 1);

  col_sink++;
  eol = 1;
  eof = 1;

  return 0;
}

void display_register(void)
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$cv_init_display";
  tf_data.calltf    = cv_init_display_calltf;
  tf_data.compiletf = 0;
  tf_data.sizetf    = 0;
  tf_data.user_data = "$cv_init_display";
  vpi_register_systf(&tf_data);

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$cv_clk_display";
  tf_data.calltf    = cv_clk_display_calltf;
  tf_data.compiletf = 0;
  tf_data.sizetf    = 0;
  tf_data.user_data = "$cv_clk_display";
  vpi_register_systf(&tf_data);

}

void (*vlog_startup_routines[])() = {
  display_register,
  0
};

/* dummy +loadvpi= boostrap routine - mimics old style exec all routines */
/* in standard PLI vlog_startup_routines table */
void vpi_compat_bootstrap(void)
{
    int i;

    for (i = 0;; i++) {
        if (vlog_startup_routines[i] == NULL)
		break; 
        vlog_startup_routines[i]();
    }
}

void __stack_chk_fail_local(void) {}

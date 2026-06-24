// DLL registration for freqTLS.
// Adapted from drmTMB::src/init.c (GPL-3, https://github.com/itchyshin/drmTMB);
// the Boolean.h pre-include guard is theirs. freqTLS is GPL-3; see LICENSE.
#include <stddef.h>
#include <Rconfig.h>
#ifdef HAVE_ENUM_BASE_TYPE
#define FREQTLS_RESTORE_HAVE_ENUM_BASE_TYPE 1
#undef HAVE_ENUM_BASE_TYPE
#endif
#include <R_ext/Boolean.h>
#ifdef FREQTLS_RESTORE_HAVE_ENUM_BASE_TYPE
#define HAVE_ENUM_BASE_TYPE 1
#endif
#include <R_ext/Rdynload.h>

void R_init_freqTLS(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, NULL, NULL, NULL);
  R_useDynamicSymbols(dll, TRUE);
}

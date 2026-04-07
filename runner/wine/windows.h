#ifndef ODA_RUNNER_WINE_WINDOWS_H
#define ODA_RUNNER_WINE_WINDOWS_H

/*
 * Wrapper header for coverage builds.
 * Some environments include <wine/windows.h> which may be missing;
 * redirect to Wine's public <windows.h>.
 */

#include <windows.h>

#endif

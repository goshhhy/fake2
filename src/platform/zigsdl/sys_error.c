/*
    This file exists solely to provide Sys_Error
*/

#include <stdio.h>
#include <stdarg.h>

void Sys_Error (char *error, ...) {
	va_list		argptr;

	printf ("Sys_Error: ");	
	va_start (argptr,error);
	vprintf (error,argptr);
	va_end (argptr);
	printf ("\n");

	exit (1);
}
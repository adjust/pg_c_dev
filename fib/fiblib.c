#include "postgres.h"

#include "fmgr.h"

PG_MODULE_MAGIC;

Datum      fib(PG_FUNCTION_ARGS);
static int fib_internal(int n);

PG_FUNCTION_INFO_V1(fib);
Datum fib(PG_FUNCTION_ARGS)
{
    int32 n, res;
    n   = PG_GETARG_INT32(0);
    res = fib_internal(n);
    PG_RETURN_INT32(res);
}

static int
fib_internal(int n)
{
    switch (n)
    {
        case 0: return 0;
        case 1: return 1;
        default: return fib_internal(n - 1) + fib_internal(n - 2);
    }
}
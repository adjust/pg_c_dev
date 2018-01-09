#include "postgres.h"

#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/timestamp.h"

PG_MODULE_MAGIC;

#ifdef HAVE_INT64_TIMESTAMP
#define USECS 1000000
#else
#define USECS 1
#endif

/*
 * Routines for UPTIME().  The transition datatype
 * is a three-element int4 array, holding last_unix_time, uptime_sum and downtime_sum.
 */
typedef struct UptimeAggState
{
    int32 last_epoch;
    int32 uptime;
    int32 downtime;
} UptimeAggState;

PG_FUNCTION_INFO_V1(uptime_sf);
// state internal, current timestamp, response_time interval, threshold interval
Datum uptime_sf(PG_FUNCTION_ARGS)
{
    UptimeAggState *state;
    Timestamp       timestamp;
    int32           current_epoch;
    Interval *      response_time;
    Interval *      threshold;
    MemoryContext   agg_context;
    MemoryContext   old_context;
    bool            first_call = false;

    if (!AggCheckCallContext(fcinfo, &agg_context))
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED), errmsg("aggregate function called in non aggregate context")));

    state = PG_ARGISNULL(0) ? NULL : (UptimeAggState *) PG_GETARG_POINTER(0);

    /* Create the state data on the first call */
    if (state == NULL)
    {
        first_call  = true;
        old_context = MemoryContextSwitchTo(agg_context);

        state = (UptimeAggState *) palloc0(sizeof(UptimeAggState));
        MemoryContextSwitchTo(old_context);
    }

    if (PG_ARGISNULL(1) || PG_ARGISNULL(3))
        PG_RETURN_POINTER(state);

    timestamp     = PG_GETARG_TIMESTAMP(1);
    threshold     = PG_GETARG_INTERVAL_P(3);
    current_epoch = (int32)(timestamp / USECS);

    // bail out for unspecific intervals
    if (threshold->day != 0 || threshold->month != 0)
        elog(ERROR, "unspecific interval");

    if (first_call)
    {
        // no elapsed time available
        state->last_epoch = current_epoch;
        PG_RETURN_POINTER(state);
    }

    if (PG_ARGISNULL(2))
    {
        // downtime case
        state->downtime += current_epoch - state->last_epoch;
        state->last_epoch = current_epoch;
        PG_RETURN_POINTER(state);
    }

    response_time = PG_GETARG_INTERVAL_P(2);

    if (response_time->day != 0 || response_time->month != 0)
        elog(ERROR, "unspecific interval");

    if (response_time->time < threshold->time)
    {
        // uptime case
        state->uptime += current_epoch - state->last_epoch;
        state->last_epoch = current_epoch;
    }
    else
    {
        // downtime case
        state->downtime += current_epoch - state->last_epoch;
        state->last_epoch = current_epoch;
    }

    PG_RETURN_POINTER(state);
}

PG_FUNCTION_INFO_V1(uptime_sf_final);
// state int[], current timestamp, response_time interval, threshold interval
// code stolen from:
// numeric.c int4_avg_accum
//
Datum uptime_sf_final(PG_FUNCTION_ARGS)
{
    UptimeAggState *state;
    int32           sum;
    Datum           total_time;
    Datum           up_time;

    state = PG_ARGISNULL(0) ? NULL : (UptimeAggState *) PG_GETARG_POINTER(0);
    if (state == NULL)
        PG_RETURN_NULL();

    sum        = state->uptime + state->downtime;
    total_time = DirectFunctionCall1(int4_numeric, Int32GetDatum(sum));

    if (sum == 0)
        PG_RETURN_DATUM(total_time);

    up_time = DirectFunctionCall1(int4_numeric, Int32GetDatum(state->uptime));

    PG_RETURN_DATUM(DirectFunctionCall2(numeric_div, up_time, total_time));
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

PG_FUNCTION_INFO_V1(fib);
Datum fib(PG_FUNCTION_ARGS)
{
    int32 n = PG_GETARG_INT32(0);
    PG_RETURN_INT32(fib_internal(n));
}
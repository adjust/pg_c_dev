
CREATE OR REPLACE FUNCTION uptime_sf(state internal, current timestamp, response_time interval, threshold interval)
RETURNS internal
AS 'uptime' LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION uptime_sf_final(internal)
RETURNS numeric
AS 'uptime' LANGUAGE C IMMUTABLE STRICT;


CREATE AGGREGATE UPTIME(timestamp, interval, interval) (
    SFUNC = uptime_sf,
    STYPE = internal,
    FINALFUNC = uptime_sf_final
);


CREATE OR REPLACE FUNCTION uptime_sf_sql(state int[], current timestamp, response_time interval, threshold interval)
RETURNS int[]
language sql
as $f$
SELECT CASE response_time < threshold
WHEN TRUE THEN
    array [ EXTRACT(EPOCH FROM current)::int, state[2] + COALESCE(EXTRACT(EPOCH FROM current)::int - state[1], 0 ), state[3] ]
ELSE
    CASE threshold IS NULL
    WHEN TRUE THEN
        state
    ELSE
        array [ EXTRACT(EPOCH FROM current)::int, state[2], state[3] + COALESCE(EXTRACT(EPOCH FROM current)::int - state[1], 0 ) ]
    END
END;
$f$;

CREATE OR REPLACE FUNCTION uptime_sf_final_sql(state int[])
RETURNS numeric
language sql
as $f$
    SELECT state[2]::numeric / NULLIF(state[2] + state[3],0);
$f$;


CREATE AGGREGATE UPTIMESQL(timestamp, interval, interval) (
    SFUNC = uptime_sf_sql,
    STYPE = INT[],
    FINALFUNC = uptime_sf_final_sql,
    INITCOND = '{NULL,0,0}'
);


CREATE OR REPLACE FUNCTION uptime_sf_plpg(state int[], current timestamp, response_time interval, threshold interval)
RETURNS int[]
language plpgsql
as $f$
    BEGIN
        IF response_time < threshold THEN
            RETURN array [ EXTRACT(EPOCH FROM current)::int, state[2] + COALESCE(EXTRACT(EPOCH FROM current)::int - state[1], 0 ), state[3] ];
        ELSE
            IF threshold IS NULL THEN
                RETURN state;
            ELSE
                RETURN array [ EXTRACT(EPOCH FROM current)::int, state[2], state[3] + COALESCE(EXTRACT(EPOCH FROM current)::int - state[1], 0 ) ];
            END IF;
        END IF;
    END;
$f$;

CREATE OR REPLACE FUNCTION uptime_sf_final_plpg(state int[])
RETURNS numeric
language plpgsql
as $f$
    BEGIN
        RETURN state[2]::numeric / NULLIF(state[2] + state[3],0);
    END;
$f$;


CREATE AGGREGATE UPTIMEPLPG(timestamp, interval, interval) (
    SFUNC = uptime_sf_plpg,
    STYPE = INT[],
    FINALFUNC = uptime_sf_final_plpg,
    INITCOND = '{NULL,0,0}'
);



/*

CREATE FUNCTION fib(integer) RETURNS integer
AS 'fiblib'
LANGUAGE C IMMUTABLE STRICT;

*/
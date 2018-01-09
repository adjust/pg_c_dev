CREATE FUNCTION fib(integer) RETURNS integer
AS 'fiblib'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fibsql(n int) RETURNS int
AS $$
    SELECT CASE n
        WHEN 0 THEN 0
        WHEN 1 THEN 1
        ELSE fibsql(n-1) + fibsql(n-2)
    END;
$$ LANGUAGE sql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION fibplp(n int) RETURNS int
AS $$
    BEGIN
        CASE n
            WHEN 0 THEN RETURN 0;
            WHEN 1 THEN RETURN 1 ;
            ELSE RETURN fibplp(n-1) + fibplp(n-2) ;
        END CASE;
    END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION fib_rec(n integer) 
RETURNS integer
AS $$
WITH RECURSIVE t(n,a,b) AS (
        VALUES(1,0,1)
    UNION ALL
        SELECT n+1, greatest(a,b), a + b AS a FROM t
        WHERE n <= $1
   )
SELECT a FROM t WHERE n=$1;
$$ LANGUAGE SQL IMMUTABLE STRICT;
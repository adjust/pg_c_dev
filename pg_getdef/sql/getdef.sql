CREATE FUNCTION get_agg(name text, args text)
RETURNS TABLE(
    SFUNC text,
    FINALFUNC text,
    STYPE text,
    COMBINEFUNC text,
    SERIALFUNC text,
    DESERIALFUNC text,
    MSFUNC text,
    MINVFUNC text,
    MFINALFUNC text,
    MSTYPE text,
    FINALFUNC_EXTRA text,
    MFINALFUNC_EXTRA text,
    SORTOP text,
    HYPOTHETICAL text,
    SSPACE text,
    INITCOND text,
    MSSPACE text,
    MINITCOND text,
    funcargs text,
    funciargs text,
    PARALLEL text
)
AS $$
SELECT
aggtransfn::text AS SFUNC,
aggfinalfn::text AS FINALFUNC,
aggtranstype::pg_catalog.regtype::text AS STYPE,
aggcombinefn::text AS COMBINEFUNC,
aggserialfn::text AS SERIALFUNC,
aggdeserialfn::text AS DESERIALFUNC,
aggmtransfn::text AS MSFUNC,
aggminvtransfn::text AS MINVFUNC,
aggmfinalfn::text AS MFINALFUNC,
aggmtranstype::pg_catalog.regtype::text AS MSTYPE,
aggfinalextra::text AS FINALFUNC_EXTRA,
aggmfinalextra::text AS MFINALFUNC_EXTRA,
aggsortop::pg_catalog.regoperator::text AS SORTOP,
(aggkind = 'h')::text AS HYPOTHETICAL,
aggtransspace::text AS SSPACE,
agginitval::text AS INITCOND,
NULLIF(aggmtransspace,0)::text AS MSSPACE,
aggminitval::text AS MINITCOND,
pg_catalog.pg_get_function_arguments(p.oid)::text AS funcargs,
pg_catalog.pg_get_function_identity_arguments(p.oid)::text AS funciargs,
CASE p.proparallel WHEN 's' THEN 'PARALLEL SAFE' WHEN 'r' THEN 'PARALLEL RESTRICTED' WHEN 'u' THEN 'PARALLEL UNSAFE' ELSE NULL END::text AS PARALLEL
FROM pg_catalog.pg_aggregate a, pg_catalog.pg_proc p
WHERE a.aggfnoid = p.oid
AND p.proname=$1
AND pg_get_function_arguments(p.oid) = $2;
$$ LANGUAGE SQL;


CREATE FUNCTION get_op(name text, left text, right text)
RETURNS TABLE(
oprkind text,
SOURCE text,
LEFTARG text,
RIGHTARG text,
COMMUTATOR text,
NEGATOR text,
RESTRICT text,
JOIN text,
MERGES text,
HASHES text
)
AS $$
SELECT CASE oprkind WHEN 'b' THEN 'both' WHEN 'l' THEN 'left' WHEN 'r' THEN 'right' END::text,
oprcode::pg_catalog.regprocedure::text AS SOURCE,
oprleft::pg_catalog.regtype::text AS LEFTARG,
oprright::pg_catalog.regtype::text AS RIGHTARG,
oprcom::pg_catalog.regoperator::text AS COMMUTATOR,
oprnegate::pg_catalog.regoperator::text AS NEGATOR,
oprrest::pg_catalog.regprocedure::text AS RESTRICT,
oprjoin::pg_catalog.regprocedure::text AS JOIN,
oprcanmerge::text AS MERGES, oprcanhash::text AS HASHES
FROM pg_catalog.pg_operator o
WHERE o.oprname = $1
AND o.oprleft::regtype::text = $2
AND o.oprright::regtype::text = $3;
$$ LANGUAGE SQL;

CREATE FUNCTION get_type(name text)
RETURNS TABLE(
    "Name" text,
    "internal Name" text,
    INTERNALLENGTH text,
    INPUT text,
    OUTPUT text,
    RECEIVE text,
    SEND text,
    TYPMOD_IN text,
    TYPMOD_OUT text,
    "ANALYZE" text,
    CATEGORY text,
    PREFERRED text,
    DELIMITER text,
    PASSEDBYVALUE text,
    ALIGNMENT text,
    STORAGE text,
    COLLATABLE text,
    "DEFAULT" text
)
AS $$
SELECT
pg_catalog.format_type(t.oid, NULL)::text AS "Name",
typname::text AS "internal Name",
typlen::text AS INTERNALLENGTH,
typinput::text AS INPUT,
typoutput::text AS OUTPUT,
typreceive ::text AS RECEIVE,
typsend::text AS SEND,
typmodin::text AS TYPMOD_IN,
typmodout::text AS TYPMOD_OUT,
typanalyze::text AS "ANALYZE",
typcategory::text AS CATEGORY,
typispreferred::text AS PREFERRED,
typdelim::text AS DELIMITER,
typbyval::text AS PASSEDBYVALUE,
CASE typalign WHEN 'c' THEN 'char' WHEN 's' THEN 'int2' WHEN 'i' THEN 'int4' WHEN 'd' THEN 'double' ELSE NULL END::text AS ALIGNMENT,
CASE typstorage WHEN 'p' THEN 'plain'WHEN 'e' THEN 'external'WHEN 'x' THEN 'extended'WHEN 'm' THEN 'main' ELSE NULL END::text AS STORAGE,
(typcollation <> 0)::text AS COLLATABLE ,
typdefault::text AS "DEFAULT"
FROM pg_catalog.pg_type t
WHERE pg_catalog.format_type(t.oid, NULL) = $1;
$$ LANGUAGE SQL;


CREATE FUNCTION get_func(name text)
RETURNS TABLE(
"Name" text,
"Result data type" text,
"Argument data types" text,
"Type" text,
"Volatility" text,
"Language" text,
"Source code" text,
"Description" text
)
AS $$
SELECT
  p.proname::text AS "Name",
  pg_catalog.pg_get_function_result(p.oid)::text AS "Result data type",
  pg_catalog.pg_get_function_arguments(p.oid)::text AS "Argument data types",
 CASE
  WHEN p.proisagg THEN 'agg'
  WHEN p.proiswindow THEN 'window'
  WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
  ELSE 'normal'
 END::text AS "Type",
 CASE
  WHEN p.provolatile = 'i' THEN 'immutable'
  WHEN p.provolatile = 's' THEN 'stable'
  WHEN p.provolatile = 'v' THEN 'volatile'
 END::text AS "Volatility",
 l.lanname::text AS "Language",
 p.prosrc::text AS "Source code",
 pg_catalog.obj_description(p.oid, 'pg_proc')::text AS "Description"
FROM pg_catalog.pg_proc p
LEFT JOIN pg_catalog.pg_language l ON l.oid = p.prolang
WHERE p.proname = $1;
$$ LANGUAGE SQL;
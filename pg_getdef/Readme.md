# pg_getdef

A postgres Extension to easily explore postgres Objects

* functions
* types
* aggregates
* operartors

### Usage

see test/expected/getdef_test.out for examples

```SQL
-- get a function definition
SELECT * FROM get_func('numeric_div');
-- get a type definition
SELECT * FROM get_type('integer');
--get an aggregate definition
SELECT * FROM get_agg('avg','integer');
--get an operartor definition
SELECT * FROM get_op('/','integer', 'integer');
```

### Installation

```shell
$ make insall
```

```SQL
CREATE EXTENSION pg_getdef;
```

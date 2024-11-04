--
--Task 2
--Note: 
--Make sure to turn autocommit on in connection settings before attempting the following tasks. Otherwise you might get an error at some
--point.
--

--drop table table_to_delete;
--
--1. Create table ‘table_to_delete’ and fill it with the following query:
--
               CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
--
--
--2. Lookup how much space this table consumes with the following query:
--
--
               SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
--
--
--3. Issue the following DELETE operation on ‘table_to_delete’:
--
               DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows
--
--
--      a) Note how much time it takes to perform this DELETE statement;
               msomething between 10 and 11s , creation took similar amount of time in this case
--      b) Lookup how much space this table consumes after previous DELETE;
               575 MB
--      c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
               VACUUM FULL VERBOSE table_to_delete;
--      d) Check space consumption of the table once again and make conclusions;
              383 MB, only after vacumm the space were released, it means that from database administrative point of view 
              using vacumm is nessesary to perform from time to time to make sure 
              to keep database expansions only in nessesary situations
--      e) Recreate ‘table_to_delete’ table;
--
--
--4. Issue the following TRUNCATE operation:
--
               TRUNCATE table_to_delete;
--      a) Note how much time it takes to perform this TRUNCATE statement.
              almost instant
--      b) Compare with previous results and make conclusion.
              truncate is much faster than delete, always remopve all contentt of table and release space to later usage
              it dosen t require vacumm to be performed 
--      c) Check space consumption of the table once again and make conclusions;
              0 bytes
--
--
--5. Hand over your investigation's results to your trainer. The results must include:
--
--      a) Space consumption of ‘table_to_delete’ table before and after each operation;
--      b) Duration of each operation (DELETE, TRUNCATE)

SELECT pg_column_size(row()) as FILA_VACIA,
       pg_column_size(row(0::SMALLINT)) as FILA_SMALL_INT,
       pg_column_size(row(0::INT)) as FILA_INT,
       pg_column_size(row(0::SMALLINT,0::INT)) as FILA_SMALL_INT_INT,
       pg_column_size(row(0::SMALLINT,0::INT,0::SMALLINT)) as FILA_SMALL_INT_INT_SMALL_INT,
       pg_column_size(row(0::BIGINT)) as FILA_BIGINT,
       pg_column_size(row(0::BIGINT,0::BIGINT, 0::INT)) as FILA_BIGINT,
       pg_column_size(row(0::BIGINT, 0::INT,0::BIGINT)) as FILA_BIGINT2,
       pg_column_size(row(0::BIGINT, 0::INT,0::SMALLINT,0::SMALLINT,0::BIGINT)) as FILA_BIGINT3,
       pg_column_size(row(0::SMALLINT,0::BIGINT, 0::INT,0::SMALLINT,0::BIGINT)) as FILA_BIGINT4
; 
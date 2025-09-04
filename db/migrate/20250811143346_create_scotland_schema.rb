class CreateScotlandSchema < ActiveRecord::Migration[8.0]
  def up
    pp "We have entered the migration function creator"
    sql = "CREATE OR REPLACE FUNCTION clone_schema(
                source_schema text,
                dest_schema text,
                include_recs boolean)
              RETURNS void AS
            $BODY$

            DECLARE
              src_oid          oid;
              func_oid         oid;
              table_rec        record;
              seq_rec          record;
              object           text;
              buffer           text;
              seq_buffer       text;
              table_buffer     text;
              qry              text;
              dest_qry         text;
              v_def            text;
              sq_last_value    bigint;
              sq_log_cnt       bigint;
              sq_is_called     boolean;

            BEGIN

            -- Check that source_schema exists
              SELECT oid INTO src_oid
                FROM pg_namespace
               WHERE nspname = source_schema;
              IF NOT FOUND
                THEN
                RAISE EXCEPTION 'source schema % does not exist!', source_schema;
                RETURN ;
              END IF;

            -- Check that dest_schema does not yet exist
              PERFORM nspname
                FROM pg_namespace
               WHERE nspname = dest_schema;
              IF FOUND
                THEN
                RAISE EXCEPTION 'dest schema % already exists!', dest_schema;
                RETURN ;
              END IF;

              EXECUTE 'CREATE SCHEMA \"' || dest_schema || '\"';

            -- Create tables
              FOR object IN
                SELECT tables.TABLE_NAME::text
                  FROM information_schema.tables as tables
                  join information_schema.columns as columns on tables.table_name = columns.table_name
                 WHERE ((tables.table_schema = 'public'
                   AND tables.table_type = 'BASE TABLE'
                    AND columns.column_name = 'assessment_id') OR tables.TABLE_NAME = 'schema_migrations') AND tables.TABLE_NAME != 'open_data_logs'

              LOOP
                buffer := '\"' || dest_schema || '\".' || quote_ident(object);
                EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE \"' || source_schema || '\".' || quote_ident(object)
                    || ' INCLUDING ALL);';

                IF include_recs
                  THEN
                  -- Insert records from source table
                  EXECUTE 'INSERT INTO ' || buffer || ' SELECT * FROM \"' || source_schema || '\".' || quote_ident(object) || ';';
                END IF;

              END LOOP;

            --  add FK constraint
              FOR qry IN
                SELECT 'ALTER TABLE \"' || dest_schema || '\".' || quote_ident(rn.relname)
                        || ' ADD CONSTRAINT ' || quote_ident(ct.conname) || ' ' || pg_get_constraintdef(ct.oid) || ';'
                  FROM pg_constraint ct
                  JOIN pg_class rn ON rn.oid = ct.conrelid
                 WHERE connamespace = src_oid
                   AND rn.relkind = 'r'
                   AND ct.contype = 'f'
                  AND rn.relname IN (SELECT tables.TABLE_NAME::text
                  FROM information_schema.tables as tables
                  join information_schema.columns as columns on tables.table_name = columns.table_name
                      WHERE (tables.table_schema = 'public'
                   AND tables.table_type = 'BASE TABLE'
                    AND columns.column_name = 'assessment_id') OR tables.TABLE_NAME = 'schema_migrations')

                LOOP
                  EXECUTE qry;

                END LOOP;

            -- Create sequences
              FOR seq_rec IN
                SELECT
                  s.sequence_name::text,
                  table_name,
                  column_name
                FROM information_schema.sequences s
                JOIN (
                  SELECT
                    substring(column_default from E'^nextval\\\\(''(?:[^\"'']?.*[\"'']?\\.)?([^'']*)''(?:::text|::regclass)?\\\\)')::text as seq_name,
                    table_name,
                    column_name
                  FROM information_schema.columns
                  WHERE column_default LIKE 'nextval%'
                    AND table_schema = source_schema
                ) c ON c.seq_name = s.sequence_name
                WHERE sequence_schema = source_schema
              LOOP
                seq_buffer := quote_ident(dest_schema) || '.' || quote_ident(seq_rec.sequence_name);

                EXECUTE 'CREATE SEQUENCE ' || seq_buffer || ';';

                qry := 'SELECT last_value, log_cnt, is_called
                          FROM \"' || source_schema || '\".' || quote_ident(seq_rec.sequence_name) || ';';
                EXECUTE qry INTO sq_last_value, sq_log_cnt, sq_is_called ;

                IF include_recs
                    THEN
                        EXECUTE 'SELECT setval( ''' || seq_buffer || ''', ' || sq_last_value || ', ' || sq_is_called || ');' ;
                ELSE
                        EXECUTE 'SELECT setval( ''' || seq_buffer || ''', ' || 1 || ', ' || sq_is_called || ');' ;
                END IF;

                table_buffer := quote_ident(dest_schema) || '.' || quote_ident(seq_rec.table_name);

                FOR table_rec IN
                  SELECT column_name::text AS column_,
                         REPLACE(column_default::text, source_schema, quote_ident(dest_schema)) AS default_
                    FROM information_schema.COLUMNS
                   WHERE table_schema = dest_schema
                     AND TABLE_NAME = seq_rec.table_name
                     AND column_default LIKE 'nextval(%' || seq_rec.sequence_name || '%::regclass)'
                LOOP
                  EXECUTE 'ALTER TABLE ' || table_buffer || ' ALTER COLUMN ' || table_rec.column_ || ' SET DEFAULT nextval(' || quote_literal(seq_buffer) || '::regclass);';
                END LOOP;

              END LOOP;

            -- Create views
              FOR object IN
                SELECT table_name::text,
                       view_definition
                  FROM information_schema.views
                 WHERE table_schema = source_schema

              LOOP
                buffer := '\"' || dest_schema || '\".' || quote_ident(object);
                SELECT view_definition INTO v_def
                  FROM information_schema.views
                 WHERE table_schema = source_schema
                   AND table_name = quote_ident(object);

                EXECUTE 'CREATE OR REPLACE VIEW ' || buffer || ' AS ' || v_def || ';' ;

              END LOOP;

            -- Create functions

              FOR func_oid IN
                SELECT p.oid
                FROM pg_proc p
                JOIN pg_language l ON p.prolang = l.oid
                WHERE p.pronamespace = src_oid
                  AND l.lanname != 'c'
              LOOP
                SELECT pg_get_functiondef(func_oid) INTO qry;
                SELECT replace(qry, source_schema, dest_schema) INTO dest_qry;
                EXECUTE dest_qry;
              END LOOP;


              RETURN;

            END;

            $BODY$
              LANGUAGE plpgsql VOLATILE
              COST 100;"

    execute(sql)
    pp "we will now execute the function"
    execute("SELECT clone_schema('public', 'scotland', false);")
  end

  def down
    execute("DROP SCHEMA IF EXISTS scotland CASCADE;")
  end
end

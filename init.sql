-- Abstract: This SQL script defines a PostgreSQL database schema for a system with key-value stores,
-- a string vault for deduplication, and bi-temporal tables for managing article and supplier data.

/*
   Transaction Isolation Level Documentation

   The SQL statement 'START TRANSACTION ISOLATION LEVEL SERIALIZABLE;' initiates a
   new database transaction with the isolation level set to "SERIALIZABLE." This
   transaction isolation level is the highest level of isolation and offers the
   strictest guarantees for data consistency and integrity.

   Key Points:
   - Serializable Isolation: The "SERIALIZABLE" isolation level ensures that
     transactions are executed in a manner that guarantees serializability. This
     means that concurrent transactions will not produce results that could not have
     been achieved by running them sequentially.
   - Locking Mechanisms: To achieve serializability, the database system may
     utilize various locking mechanisms to prevent concurrent transactions from
     accessing the same data simultaneously.
   - Data Integrity: "SERIALIZABLE" isolation provides a high level of data integrity,
     making it suitable for scenarios where maintaining strict data consistency is
     critical.

   Usage:
   - This isolation level is typically chosen when there is a need to prevent
     anomalies like dirty reads, non-repeatable reads, and phantom reads in a
     high-concurrency environment.
   - It ensures that transactions are executed in a manner that preserves the
     consistency of data, even in the presence of concurrent access.

   Caution:
   - Using "SERIALIZABLE" isolation may impact performance, as it can lead to
     increased contention and potential blocking of concurrent transactions.

   Example:
   - Starting a new transaction with "SERIALIZABLE" isolation:
     START TRANSACTION ISOLATION LEVEL SERIALIZABLE;

   It's important to consider the specific requirements of your application and
   the potential performance implications when choosing this isolation level.
*/
start transaction isolation level serializable;

/*

    run your own database using docker:

     docker run --name postgres -e POSTGRES_PASSWORD=test*12* -p 5432:5432 -d orion6docker/pg-german
    
     for performance reasons, the cns subsystem is implemented using
     PL/pgSQL — sql procedural language for PostgreSQL.
    
     https://www.postgresql.org/docs/current/plpgsql.html
    
    Mimetypes:
    
     - https://www.nuget.org/packages/MimeTypes
     - https://www.freeformatter.com/mime-types-list.html
    
 */

/*

This script prepares your PostgreSQL database by adding useful features.
It uses the CREATE LANGUAGE and CREATE EXTENSION commands to add support for
additional programming languages and load additional functionality into
PostgreSQL.
*/

/* 
Creates (or replaces, if it exists) the language "plpython3u" for PostgreSQL. 
This allows user-defined functions to be written in Python 3. "plpython3u" 
runs as non-trusted (unrestricted), meaning they can perform any operation 
that the operating-system user running the server has permission for.
More information: https://www.postgresql.org/docs/current/plpython.html
*/
create or replace language "plpython3u";

/*
   Database Extensions Creation Documentation

   The following SQL statements are used to create database extensions if they do
   not already exist. Database extensions are additional features or functions
   that can be added to a PostgreSQL database to enhance its capabilities.

   Extensions Created:
   1. ltree: The "ltree" extension provides support for hierarchical or tree-like
      structures, allowing you to work with tree data within the database.
   2. pgcrypto: The "pgcrypto" extension provides cryptographic functions and
      utilities for secure data storage and retrieval.
   3. hstore: The "hstore" extension adds support for the "hstore" data type, which
      is a key-value store within a PostgreSQL database.
   4. "uuid-ossp": The "uuid-ossp" extension enables the generation of universally
      unique identifiers (UUIDs) based on the OSSP UUID library.

   Usage:
   - These extensions can be useful for various database operations, including
     working with hierarchical data, securing sensitive information, managing
     key-value data, and generating UUIDs.

   Caution:
   - Ensure that you have the necessary privileges to create extensions in the
     database.
   - Be cautious when enabling extensions, as they may impact the behavior and
     performance of your database.

   Example:
   - Creating extensions if they do not already exist:
     CREATE EXTENSION IF NOT EXISTS ltree;
     CREATE EXTENSION IF NOT EXISTS pgcrypto;
     CREATE EXTENSION IF NOT EXISTS hstore;
     CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

   It's important to evaluate your specific database requirements and only enable
   extensions that are relevant to your application's needs.
*/

/*
Installs the "ltree" extension if it isn't already installed. The ltree 
module implements data types for hierarchical tree-like structures like 
paths in a file system and provides built-in functions to manage and query this data.
More information: https://www.postgresql.org/docs/current/ltree.html
*/
create extension if not exists ltree;

/*
Installs the "pgcrypto" extension if it isn't already installed. pgcrypto is 
a cryptographic extension for PostgreSQL. It provides several functions for hashing, 
data encryption, and random number generation.
More information: https://www.postgresql.org/docs/current/pgcrypto.html
*/
create extension if not exists pgcrypto;

/* 
Installs the "hstore" extension if it isn't already installed. hstore is a 
PostgreSQL extension for storing key-value pairs within a single PostgreSQL value. 
It's useful in various scenarios, such as rows with many attributes that are rarely
queried, or semi-structured data.
More information: https://www.postgresql.org/docs/current/hstore.html
*/
create extension if not exists hstore;

/*
Installs the "uuid-ossp" extension if it isn't already installed. uuid-ossp is 
a PostgreSQL extension that provides functions to generate universally unique 
identifiers (UUIDs) using one of several standard algorithms. UUIDs can be used 
for creating unique values for identifiers, preventing collisions.
More information: https://www.postgresql.org/docs/current/uuid-ossp.html
*/
create extension if not exists "uuid-ossp";

-- https://stackoverflow.com/questions/31445386/how-can-i-get-mime-type-of-bytea-stored-in-postgresql

/*
  1) mimemagic: a function that analyses input data and returns its MIME type. 
     This function can be used to quickly identify the format of the stored data 
     without having to go through the entire content. To achieve this, the function
     uses the 'magic' Python library.
     
     Usage:
     SELECT mimemagic(your_data::bytea);
     
     Params: 
     data: bytea - The input data to analyze.
    
     Returns: 
     text - The MIME type of input data.
 */
create or replace function mimemagic(data bytea) returns text as
$$
import magic
return magic.from_buffer(data, mime=True)
$$ language plpython3u;

/* 
  2) compress: a function that compresses the input data using the 'zlib' Python 
     library. This can be useful when storing large amounts of data to save 
     disk space.
     
     Usage:
     SELECT compress(your_data::bytea);
    
     Params: 
     data: bytea - The input data to compress.
    
     Returns: 
     bytea - The compressed data.
*/
create or replace function compress(data bytea) returns bytea as
$$
import zlib
return zlib.compress(data)
$$ language plpython3u;

/*  
  3) decompress: a function that decompresses the input data compressed 
     by the 'zlib' Python library. Useful when retrieving the original 
     data that has been previously compressed using the 'compress' 
     function.
    
     Usage:
     SELECT decompress(your_data::bytea);
    
     Params: 
     data: bytea - The compressed data to decompress.
    
     Returns: 
     bytea - The original, decompressed data.
*/    
create or replace function decompress(data bytea) returns bytea as
$$
import zlib
return zlib.decompress(data)
$$ language plpython3u;

/*
     Note: 'mimemagic', 'compress' and 'decompress' stored procedures 
     use the 'plpython3u' PostgreSQL language extension that enables 
     writing functions in Python 3.
*/

/*
   Table Documentation for 'rt_string_vault'

   The 'rt_string_vault' table is designed to serve as a centralized repository for
   storing strings with deduplication. It provides a mechanism to efficiently store
   and manage unique string values while associating them with a timestamp.

   Table Columns:
   - 'id' (serial primary key): An auto-incremented unique identifier for each record
     in the table. This column serves as the primary key.
   - 'value' (text): The actual string value to be stored in the vault. This column
     is used to store the unique string values.
   - 'created_on' (timestamp without time zone): A timestamp that indicates when the
     string value was added to the vault. It is set to the current timestamp in UTC
     by default.

   Usage:
   - The 'rt_string_vault' table is useful in scenarios where there is a need to
     maintain a repository of unique string values to prevent duplication and
     efficiently manage string data.
   - Strings can be added to the vault using INSERT statements, and the system
     will automatically ensure that only unique values are stored.
   - The 'created_on' timestamp provides information about when each string value
     was added to the vault.

   Example:
   - To insert a unique string value into the 'rt_string_vault' table:
     INSERT INTO rt_string_vault (value) VALUES ('Unique String Value');

   This table facilitates the efficient storage and retrieval of unique string
   values while maintaining a record of their creation timestamps.
*/
create table rt_string_vault
(
    id         serial primary key,                                            -- serial id
    value      text,                                                          -- the string value
    created_on timestamp without time zone default (now() at time zone 'utc') -- timestamp
);

-- Insert default strings into the string vault
INSERT INTO rt_string_vault(value) VALUES ('');
INSERT INTO rt_string_vault(value) VALUES (' ');
INSERT INTO rt_string_vault(value) VALUES ('0');
INSERT INTO rt_string_vault(value) VALUES ('1');
INSERT INTO rt_string_vault(value) VALUES ('2');
INSERT INTO rt_string_vault(value) VALUES ('3');
INSERT INTO rt_string_vault(value) VALUES ('4');
INSERT INTO rt_string_vault(value) VALUES ('5');
INSERT INTO rt_string_vault(value) VALUES ('6');
INSERT INTO rt_string_vault(value) VALUES ('7');
INSERT INTO rt_string_vault(value) VALUES ('8');
INSERT INTO rt_string_vault(value) VALUES ('9');
INSERT INTO rt_string_vault(value) VALUES ('locked');
INSERT INTO rt_string_vault(value) VALUES ('unlocked');
INSERT INTO rt_string_vault(value) VALUES ('maintenance');
INSERT INTO rt_string_vault(value) VALUES ('error');
INSERT INTO rt_string_vault(value) VALUES ('active');

-- Create a unique index for string deduplication
CREATE UNIQUE INDEX rt_string_vault_idx_value ON rt_string_vault (value);

-- Separator
-----------------------------------------------------

/*
   Function: rt_appendstring

   Description:
   This PostgreSQL function, named 'rt_appendstring', is designed to add string
   values to a table called 'rt_string_vault' with deduplication. It takes a single
   input parameter of type 'text' and returns an integer ('int4').

   Function Signature:
   - Parameters:
     - $1 (Input, text): The string value to be added to the 'rt_string_vault' table.

   Function Behavior:
   - If the input string ($1) is null, the function returns 1 without performing any
     further actions.
   - If the input string ($1) is not null, the function checks if a record with the
     same 'value' exists in the 'rt_string_vault' table.
     - If a matching record is found, the function retrieves the 'id' (integer) of
       the existing record into the 'key' variable.
     - If no matching record is found, the function inserts the input string ($1)
       into the 'rt_string_vault' table, and it returns the newly generated serial
       'id' for the inserted record using 'currval'.
   - In both cases, the function returns an integer ('int4') representing either the
     'id' of the existing record or the 'id' of the newly inserted record.

   Example Usage:
   - To add a string to the 'rt_string_vault' table and retrieve its associated 'id':
     SELECT rt_appendstring('Sample String');

   Caution:
   - Ensure that the 'rt_string_vault' table exists with the required schema before
     using this function.
   - The function performs deduplication by checking for existing string values in
     the table and does not insert duplicate strings.

   Note:
   - This function is designed for scenarios where you want to maintain a unique set
     of string values with associated identifiers, useful for optimizing storage
     and retrieval of string data.

   Function Definition:
   - The function is implemented in PL/pgSQL language and uses conditional logic to
     manage the insertion and retrieval of string values in the 'rt_string_vault'
     table.
*/
-- Function: rt_appendstring(text)
-- Returns: int4
-- Language: plpgsql

create or replace function rt_appendstring(text)
    returns int4
    language plpgsql
as
$$
declare
    key int4;
begin
    if ($1 is null) then
        return 1;
    end if;

    select
        id
    from
        rt_string_vault
    where
        value = $1
    into key;

    if (key is null) then
        insert
        into rt_string_vault (value) values ($1);
        return currval(pg_get_serial_sequence('rt_string_vault', 'id'));
    end if;

    return key;
end
$$;

/*
   Table: rt_key_value

   Description:
   The 'rt_key_value' table is designed to store key-value pairs, where 'key_id' and
   'value_id' are integers ('int4'). This table allows you to establish relationships
   between keys and corresponding values.

   Table Structure:
   - 'key_id' (Primary Key, int4): This column represents the key in the key-value
     pair. It serves as the primary identifier for a specific key-value relationship.
     It must be unique within the table.

   - 'value_id' (int4): This column represents the associated value for the key. It
     stores the identifier of the corresponding value in the key-value relationship.

   Usage and Purpose:
   - The 'rt_key_value' table is commonly used to create flexible relationships
     between entities in a database. Each 'key_id' is associated with a specific
     'value_id', allowing you to represent various associations, mappings, or
     configurations in your database.

   Example Usage:
   - You can use this table to create associations between various entities. For
     instance, you might use it to associate a product 'key_id' with its respective
     category 'value_id' in an e-commerce system.

   Constraints:
   - 'key_id' is defined as the primary key of the table, ensuring that each key is
     unique within the table.

   Important Notes:
   - Ensure that you manage and maintain the integrity of the data in this table,
     especially when establishing relationships between keys and values.

   Table Definition:
   - The 'rt_key_value' table consists of two columns, 'key_id' and 'value_id', both
     of which are of integer type ('int4').
   - 'key_id' serves as the primary key for the table.

   Example Creation:
   - To create the 'rt_key_value' table, you can use the following SQL statement:
     CREATE TABLE rt_key_value (
         key_id   int4 PRIMARY KEY,
         value_id int4
     );

   Caution:
   - Ensure that 'key_id' values remain unique to maintain the integrity of the
     relationships stored in this table.
*/
-- Table: rt_key_value
create table rt_key_value
(
    key_id   int4 primary key,
    value_id int4
);

/*
   View: rt_key_value_view

   Description:
   The 'rt_key_value_view' is a view that provides a convenient way to query and retrieve
   key-value pairs from the 'rt_key_value' table, presenting them in a more readable
   format. This view joins the 'rt_key_value' table with the 'rt_string_vault' table to
   display key-value pairs as 'key', 'value', 'key_id', and 'value_id' columns.

   View Structure:
   - 'key' (text): This column represents the key in the key-value pair, extracted from
     the 'rt_string_vault' table.

   - 'value' (text): This column represents the associated value for the key, extracted
     from the 'rt_string_vault' table.

   - 'key_id' (int4): This column contains the identifier ('key_id') for the key-value
     relationship from the 'rt_key_value' table.

   - 'value_id' (int4): This column contains the identifier ('value_id') for the value
     associated with the key from the 'rt_key_value' table.

   Usage and Purpose:
   - The 'rt_key_value_view' simplifies the retrieval of key-value pairs from the
     'rt_key_value' table by providing a clear and organized view.

   Example Usage:
   - You can use this view to query key-value pairs, making it easier to work with
     settings, configurations, or dynamic data stored in your database.

   View Definition:
   - The 'rt_key_value_view' view retrieves key-value pairs from the 'rt_key_value'
     table and 'rt_string_vault' table and presents them with the columns 'key',
     'value', 'key_id', and 'value_id'.

   Example Creation:
   - To create the 'rt_key_value_view' view, you can use the following SQL statement:
     CREATE VIEW rt_key_value_view AS
     SELECT
         b.value AS key,
         c.value AS value,
         b.id    AS key_id,
         c.id    AS value_id
     FROM
         rt_key_value a
         INNER JOIN rt_string_vault b ON a.key_id = b.id
         INNER JOIN rt_string_vault c ON a.value_id = c.id;

   Important Notes:
   - This view simplifies the retrieval of key-value pairs and enhances the usability
     of the 'rt_key_value' table.
*/
-- View: rt_key_value_view
create view rt_key_value_view as
select
    b.value as key,
    c.value as value,
    b.id    as key_id,
    c.id    as value_id
from
    rt_key_value a
        inner join rt_string_vault b on a.key_id = b.id
        inner join rt_string_vault c on a.value_id = c.id;

/*
   Function: rt_set_key_value

   Description:
   The 'rt_set_key_value' function is designed to set or update key-value pairs in the
   'rt_key_value' table. It takes two parameters: 'key' and 'value', and performs the
   following actions:
   
   1. It retrieves or creates identifiers (key_id and value_id) for the 'key' and
      'value' parameters using the 'rt_appendstring' function.
   
   2. It inserts the key-value pair into the 'rt_key_value' table, associating the
      'key_id' with the 'value_id'.

   3. In case of a conflict on the 'key_id' (indicating an update to an existing
      key-value pair), it updates the 'value_id' to the new 'value_id'.

   The function returns the 'key_id' of the inserted or updated key-value pair.

   Parameters:
   - 'key' (text): The key for the key-value pair.
   - 'value' (text): The value associated with the key.

   Usage and Purpose:
   - The 'rt_set_key_value' function simplifies the process of managing key-value pairs
     in the 'rt_key_value' table by providing a high-level interface to set or update
     key-value pairs.

   Example Usage:
   - You can use this function to set or update key-value pairs, making it easy to
     manage dynamic data, settings, or configurations in your database.

   Function Implementation:
   - The function first obtains 'key_id' and 'value_id' for the 'key' and 'value'
     parameters using the 'rt_appendstring' function.
   
   - It then inserts the key-value pair into the 'rt_key_value' table, associating
     'key_id' with 'value_id'. If a conflict occurs on 'key_id', it updates 'value_id'
     to the new 'value_id'.

   Important Notes:
   - This function simplifies the management of key-value pairs and enhances the
     usability of the 'rt_key_value' table.
*/
-- Function: rt_set_key_value
create or replace function rt_set_key_value(p_key text, p_value text)
    returns int4
    language plpgsql
as $$
<<local>>
    declare
    l_key_id   int4;
    l_value_id int4;
begin
    local.l_key_id = rt_appendstring(p_key);
    local.l_value_id = rt_appendstring(p_value);

    insert into rt_key_value (key_id, value_id) values (local.l_key_id, local.l_value_id)
    on conflict (key_id) do update set key_id = local.l_key_id, value_id = local.l_value_id;

    return l_key_id;
end
$$;

/*
   Function: rt_get_key_value

   Description:
   The 'rt_get_key_value' function is designed to retrieve the value associated with a
   specific key from the 'rt_key_value_view'. It takes one parameter, 'p_key', and
   performs the following actions:

   1. It queries the 'rt_key_value_view' to find the value associated with the provided
      'p_key'.

   2. If a matching key is found in the 'rt_key_value_view', the associated value is
      returned. If no match is found, the function returns NULL.

   Parameters:
   - 'p_key' (text): The key for which you want to retrieve the associated value.

   Usage and Purpose:
   - The 'rt_get_key_value' function simplifies the process of retrieving values
     associated with specific keys in the 'rt_key_value_view'.

   Example Usage:
   - You can use this function to retrieve configuration values, settings, or other
     data stored as key-value pairs in the 'rt_key_value_view'.

   Function Implementation:
   - The function queries the 'rt_key_value_view' to find the value associated with the
     provided 'p_key'. If a match is found, it is stored in the 'value' variable, which
     is returned as the function's result.

   Important Notes:
   - This function simplifies the retrieval of values associated with keys in the
     'rt_key_value_view', making it convenient to access configuration data and settings.
*/
-- Function: rt_get_key_value
create or replace function rt_get_key_value(p_key text)
    returns text
    language plpgsql
as $$
<<local>>
    declare
    value text;
begin
    select rt_key_value_view.value
    from rt_key_value_view
    where rt_key_value_view.key = p_key
    into local.value;

    return local.value;
end
$$;

/*
   Function: rt_get_key_value_id

   Description:
   The 'rt_get_key_value_id' function is designed to retrieve the unique identifier (ID)
   associated with a specific key from the 'rt_string_vault' table. It takes one
   parameter, 'p_key', and performs the following actions:

   1. It queries the 'rt_string_vault' table to find the ID associated with the provided
      'p_key'.

   2. If a matching key is found in the 'rt_string_vault' table, the associated ID is
      returned. If no match is found, the function returns NULL.

   Parameters:
   - 'p_key' (text): The key for which you want to retrieve the associated ID.

   Usage and Purpose:
   - The 'rt_get_key_value_id' function simplifies the process of obtaining the ID
     associated with a specific key in the 'rt_string_vault' table.

   Example Usage:
   - You can use this function when you need to retrieve the unique identifier (ID)
     associated with a particular key, allowing you to perform operations based on that
     ID.

   Function Implementation:
   - The function queries the 'rt_string_vault' table to find the ID associated with the
     provided 'p_key'. If a match is found, it is stored in the 'id' variable, which is
     returned as the function's result.

   Important Notes:
   - This function simplifies the retrieval of IDs associated with keys in the
     'rt_string_vault' table, facilitating various database operations.
*/
-- Function: rt_get_key_value_id
create or replace function rt_get_key_value_id(p_key text)
    returns text
    language plpgsql
as $$
<<local>>
    declare
    id int4;
begin
    select rt_string_vault.id
    from rt_string_vault
    where p_key = rt_string_vault.value
    into local.id;

    return local.id;
end
$$;

/*
   Table: rt_key_multiple_value

   Description:
   The 'rt_key_multiple_value' table is designed to store multiple values associated
   with a specific key. It facilitates a many-to-many relationship between keys and
   values by using two integer columns: 'key_id' and 'value_id'. The combination of
   these two columns forms the primary key for this table.

   Table Columns:
   - 'key_id' (integer): Represents the identifier associated with a key stored in the
     'rt_string_vault' table.
   - 'value_id' (integer): Represents the identifier associated with a value stored in
     the 'rt_string_vault' table.

   Primary Key:
   - The primary key of this table is a composite key consisting of both 'key_id' and
     'value_id'. This ensures that each combination of key and value is unique.

   Usage and Purpose:
   - The 'rt_key_multiple_value' table is useful when you need to associate multiple
     values with a single key efficiently. It supports many-to-many relationships
     between keys and values.

   Example Usage:
   - You can use this table to implement scenarios where one key can be associated
     with multiple values. For instance, it can be used in settings where tags or
     categories need to be associated with various items.

   Important Notes:
   - Ensure that 'key_id' and 'value_id' correspond to valid identifiers in the
     'rt_string_vault' table, which typically contains keys and their associated
     values.
*/
-- Table: rt_key_multiple_value
create table rt_key_multiple_value
(
    key_id   integer,
    value_id integer,
    primary key (key_id, value_id)
);

/*
   View: rt_key_multiple_value_view

   Description:
   The 'rt_key_multiple_value_view' is a database view designed to provide a readable
   representation of associations between keys and multiple values stored in the
   'rt_key_multiple_value' table. It serves as a convenient way to access and query
   these associations.

   View Columns:
   - 'key' (text): Represents the key value associated with a specific association.
   - 'value' (text): Represents the value associated with a specific association.
   - 'key_id' (integer): Corresponds to the identifier of the key in the 'rt_string_vault'
     table.
   - 'value_id' (integer): Corresponds to the identifier of the value in the 'rt_string_vault'
     table.

   Usage and Purpose:
   - The 'rt_key_multiple_value_view' view simplifies the process of retrieving and
     querying associations between keys and multiple values. It provides a more
     human-readable representation of these relationships, making it easier to work
     with the data.

   Example Usage:
   - You can use this view to retrieve all the key-value associations and their
     corresponding identifiers. For instance, it can be useful when you want to list
     all tags associated with various items in a user-friendly format.

   Important Notes:
   - Ensure that 'key_id' and 'value_id' correspond to valid identifiers in the
     'rt_string_vault' table, which typically contains keys and their associated
     values.
*/
-- View: rt_key_multiple_value_view
create view rt_key_multiple_value_view as
select
    b.value as key,
    c.value as value,
    b.id    as key_id,
    c.id    as value_id
from
    rt_key_multiple_value a
        inner join rt_string_vault b on a.key_id = b.id
        inner join rt_string_vault c on a.value_id = c.id;


/*
   Function: rt_set_key_multiple_value

   Description:
   The 'rt_set_key_multiple_value' function is designed to associate a key with
   multiple values in the 'rt_key_multiple_value' table. It allows the insertion
   of new associations between keys and values, ensuring uniqueness in the
   associations.

   Parameters:
   - 'p_key' (text): Represents the key to be associated with one or more values.
   - 'p_value' (text): Represents the value to be associated with the key.

   Return Value:
   - The function returns a record with two fields:
     - 'key_id' (integer): Corresponds to the identifier of the key in the 'rt_string_vault'
       table.
     - 'value_id' (integer): Corresponds to the identifier of the value in the 'rt_string_vault'
       table.

   Usage and Purpose:
   - The 'rt_set_key_multiple_value' function simplifies the process of creating
     associations between keys and multiple values. It allows for the efficient
     creation of these associations while ensuring that duplicate associations
     are avoided.

   Example Usage:
   - You can use this function to associate tags with items in a database. When
     inserting a new tag-item association, you can call this function to create
     the association and retrieve the identifiers of the key and value for further
     reference.

   Important Notes:
   - Ensure that 'key_id' and 'value_id' correspond to valid identifiers in the
     'rt_string_vault' table, which typically contains keys and their associated
     values.
*/
-- Function: rt_set_key_multiple_value
create or replace function rt_set_key_multiple_value(p_key text, p_value text)
    returns record
    language plpgsql
as $$
<<local>>
    declare
    key_id   integer;
    value_id integer;
    return_record  record;
begin
    local.key_id = rt_appendstring(p_key);
    local.value_id = rt_appendstring(p_value);

    insert into rt_key_multiple_value (key_id, value_id)
    values (local.key_id, local.value_id)
    on conflict do nothing;

    select local.key_id, local.value_id into local.return_record;

    return local.return_record;
end
$$;

/*
   Table: uuid_lookup

   Description:
   The 'uuid_lookup' table is used to associate universally unique identifiers (UUIDs)
   with business keys and additional metadata. It serves as a lookup table that links
   UUIDs to specific entities, allowing for efficient retrieval and management of
   UUID-based references.

   Column Definitions:
   - 'id' (uuid): Represents the universally unique identifier (UUID) associated
     with an entity. It serves as the primary key of the table and is used as the
     key for UUID-based lookups.
   - 'business_key' (bigint): Corresponds to the business key or identifier that
     uniquely identifies an entity. This column is included in the primary key for
     efficient retrieval of entities using their business keys.
   - 'type_id' (integer, default 0): Represents an optional type identifier that
     categorizes the associated entity. It is used to classify entities into
     different categories or types.
   - 'time_generated_assigned' (timestamp, default now()): Indicates the timestamp
     when the UUID was generated or assigned to the entity. It is useful for tracking
     when UUID assignments occurred.

   Primary Key:
   - The primary key of this table consists of the 'id' column, which uniquely
     identifies each UUID, and the 'business_key' column, which allows for efficient
     lookups based on business keys.

   Usage and Purpose:
   - The 'uuid_lookup' table is essential for managing UUID-based references in a
     database. It facilitates the mapping between UUIDs and business keys, making it
     easier to retrieve and reference entities in a universally unique manner.

   Example Use Cases:
   - Use this table to associate UUIDs with various entities, such as users, products,
     or assets. This association simplifies cross-referencing and ensures the
     uniqueness of UUIDs across the database.

   Important Notes:
   - When inserting data into this table, ensure that the 'id' column contains valid
     UUIDs, the 'business_key' column contains unique business keys, and the 'type_id'
     column is used consistently to categorize entities.
*/
-- Table: uuid_lookup
create table uuid_lookup
(
    id                      uuid,
    business_key            bigint,
    type_id                 integer default 0,
    time_generated_assigned timestamp default now(),
    primary key (id) include (business_key)
);

/*
   Function: associate_business_key

   Description:
   The 'associate_business_key' function is used to associate a universally unique
   identifier (UUID) with a unique business key. It checks whether the UUID is already
   associated with a business key in the 'uuid_lookup' table. If the UUID is found, it
   returns the existing business key; otherwise, it generates a new business key and
   associates it with the provided UUID.

   Parameters:
   - 'p_uuid' (uuid): The UUID that needs to be associated with a business key.

   Return Value:
   - 'bigint': The function returns a bigint representing the associated or generated
     business key.

   Function Implementation:
   - The function first attempts to retrieve the business key associated with the
     provided UUID from the 'uuid_lookup' table. If a match is found, it returns the
     existing business key.
   - If no match is found, the function generates a new business key using the
     'business_key_seq' sequence and inserts the UUID-business key association into
     the 'uuid_lookup' table.
   - Finally, the function returns the associated or newly generated business key.

   Usage and Purpose:
   - This function is crucial for managing UUID-business key associations in a
     database. It ensures that UUIDs are consistently linked to unique business keys,
     facilitating entity identification and retrieval.

   Example Use Cases:
   - Use this function whenever you need to associate a UUID with a business key,
     such as when inserting new entities with UUIDs or performing UUID-based lookups.

   Important Notes:
   - Ensure that the 'uuid_lookup' table is populated with UUID-business key
     associations before using this function.
   - The 'business_key_seq' sequence should be correctly configured to generate
     unique business keys.
*/
-- Function: associate_business_key
create or replace function associate_business_key(p_uuid uuid)
    returns bigint
as $$
declare
    business_key bigint;
begin
    select uuid_lookup.business_key
    from uuid_lookup
    where id = p_uuid
    into business_key;

    if found then
        return business_key;
    end if;

    business_key := nextval('business_key_seq');

    insert into uuid_lookup (id, business_key) values (p_uuid, business_key);

    return business_key;
end
$$ language plpgsql;

/*
   Sequences: business_key_seq and row_id_seq

   Description:
   Sequences 'business_key_seq' and 'row_id_seq' are used to generate unique integer
   values that serve as keys for identifying records in specific tables. These
   sequences are typically employed as primary key values in tables where they ensure
   the uniqueness and integrity of records.

   'business_key_seq' Sequence:
   - 'business_key_seq' is designed to generate unique business keys, which are
     used as identifiers for business entities. These keys are essential for ensuring
     that each entity in the database has a distinct identifier.

   'row_id_seq' Sequence:
   - 'row_id_seq' is used to generate unique row identifiers. These identifiers are
     often employed in bi-temporal databases to distinguish different versions or
     states of an entity over time. They serve as temporal identifiers within the
     bi-temporal framework.

   Sequence Creation:
   - These sequences can be created using the following SQL statements:
     CREATE SEQUENCE business_key_seq;
     CREATE SEQUENCE row_id_seq;

   Usage and Purpose:
   - 'business_key_seq' is typically used to generate primary key values for tables
     that represent business entities or records.
   - 'row_id_seq' is commonly utilized in tables where temporal tracking of entities
     is required, allowing differentiation between different versions of the same
     entity.

   Important Notes:
   - Ensure that the sequences are correctly initialized and configured before using
     them as primary key generators in tables.
   - Sequences should be used consistently to maintain data integrity and uniqueness.

   Example Usage:
   - After creating these sequences, you can use them in INSERT statements to
     generate unique primary key values for specific tables. For example:
     INSERT INTO some_table (id, column1, column2)
     VALUES (nextval('business_key_seq'), 'Value1', 'Value2');

   Sequence Alteration:
   - Sequences can be altered to modify their behavior, such as changing the initial
     value or increment value. Refer to PostgreSQL documentation for sequence
     alteration syntax.

   Sequence Removal:
   - Sequences can be dropped if they are no longer needed using the DROP SEQUENCE
     statement. Exercise caution when dropping sequences to avoid data integrity
     issues.
*/
create sequence business_key_seq;
create sequence row_id_seq;

-------------------------------------------------------------------------------
-- bi_temporal_base_table
-------------------------------------------------------------------------------

/*
   DDL Documentation for bi_temporal_base_table

   This table, 'bi_temporal_base_table', is designed to support bi-temporal data
   management, which tracks time validity, decision time, and database transaction
   time for records. 

   Column Definitions:
   - 'id': A unique identifier for each record in the table. It is of BIGINT data
     type and is automatically generated using the 'business_key_seq' sequence.
   - 'row_id': A unique identifier for each row in the table, also automatically
     generated using the 'row_id_seq' sequence.
   - 'valid_time': Represents the time range during which the record is considered
     valid. It uses the 'TSTZRANGE' data type and has a default value that starts
     from the current time in UTC and extends to infinity.
   - 'decision_time': Indicates the time range during which a decision was made
     regarding the record. It uses the 'TSTZRANGE' data type and has a default
     value starting from the current time in UTC and extending to infinity.
   - 'db_tx_time': Represents the time range during which the record was modified
     as part of a database transaction. It also uses the 'TSTZRANGE' data type and
     has a default value starting from the current time in UTC and extending to
     infinity.

   Primary Key:
   - The primary key of this table consists of two columns: 'id' and 'row_id'. This
     ensures each record is uniquely identified within the table.

   This table serves as a base for bi-temporal data management and will likely be
   extended by other tables to capture specific data domains.

   The 'id' and 'row_id' combination in this table serves a crucial role in
   pointing to an entity in time. While 'id' alone identifies a unique entity
   that evolves over time, 'row_id' further distinguishes different versions
   or states of that entity. Together, they form a composite primary key that
   allows us to track changes and variations of the same entity over time. 'id'
   represents a persistent identifier for the entity, ensuring that we can
   refer to the same entity across different temporal states. On the other hand,
   'row_id' serves as a temporal identifier, indicating the specific version or
   snapshot of the entity within the bi-temporal framework. This combination
   enables precise temporal querying and tracking of historical and current
   states of entities in the database.   
*/

/*
   Developer's Documentation for 'row_id'

   In our database model, the 'row_id' serves as a pivotal attribute with a
   database-wide sequence generating a unique ID for every row. This attribute
   plays a fundamental role in ensuring data integrity and facilitating
   temporal data management.

   The uniqueness of 'row_id' guarantees that each row within the database is
   distinguishable, providing an unambiguous identifier for individual records.
   Consequently, it becomes an invaluable tool for tracking the temporal aspects
   of data changes.

   One of the key characteristics of 'row_id' is its association with the 'id'
   attribute within a transaction. In practice, the highest 'row_id' for a given
   'id' represents the newest entry or the most recent state of that entity within
   the context of the transaction.

   This behavior allows for efficient retrieval of the latest entry for a specific
   entity. By selecting an entity by 'id' ordered by 'row_id' in descending order
   and limiting the result to 1, developers can consistently obtain the most
   recent version or snapshot of that entity within the scope of a transaction.

   Example Query:
   SELECT *
   FROM bi_temporal_base_table
   WHERE id = 'your_entity_id'
   ORDER BY row_id DESC
   LIMIT 1;

   In this query, substituting 'your_entity_id' with the desired entity identifier
   will reliably retrieve the latest entry for that entity within the current
   transaction.

   The 'row_id' attribute, in conjunction with 'id,' facilitates precise temporal
   querying and tracking of historical and current states of entities in the
   database, making it an integral part of our bi-temporal data management strategy.
*/

/*
   Developer's Documentation for 'db_tx_time'

   The 'db_tx_time' column in this table plays a crucial role in enabling time travel
   within the database. It represents a closed-open interval that records the time
   range during which a particular row or entity was modified as part of a database
   transaction. The interval is expressed in the 'TSTZRANGE' data type, ensuring
   precise temporal tracking.

   How 'db_tx_time' is Used:
   - To Time Travel: When performing a time travel query, the 'db_tx_time' column is
     queried to find rows where the 'QueryTxTime' falls within the interval. This
     effectively retrieves the state of an entity at a specific point in time defined
     by 'QueryTxTime'. If there is a row for a given 'id' where 'QueryTxTime' is
     inside the 'db_tx_time' interval, it indicates that the entity with that 'id'
     exists at that particular time.

   Entity Existence Determination:
   - If there is no row in the table for a given 'id' where 'QueryTxTime' falls
     inside the 'db_tx_time' interval, it implies that the entity identified by the
     'id' does not exist at that precise point in time. This mechanism provides a
     powerful means to verify the existence of entities throughout the database's
     temporal history.

   'db_tx_time' thus facilitates accurate time-based querying and ensures that the
   database can be effectively navigated to examine entity states at different
   moments in its history.
*/

/*
   Developer's Documentation for 'valid_time'

   The 'valid_time' column within the 'bi_temporal_base_table' is a pivotal component
   of the bi-temporal data management framework. It represents a time range during
   which a specific record is considered valid. This temporal validity concept is
   particularly valuable for scenarios where historical and current states of data
   need to be tracked and queried.

   For example, consider a scenario in which the 'bi_temporal_base_table' contains
   records representing product prices over time. The 'valid_time' column for each
   record specifies the period during which that price was valid. If a user wants to
   retrieve the price of a product as it stood on a particular date, they can use
   'valid_time' to filter the records to find the one with a 'valid_time' interval
   containing the desired date.

   Example Query:
   SELECT price
   FROM bi_temporal_base_table
   WHERE product_id = '123'
   AND '2023-06-15'::timestamptz <@ valid_time;

   In this example, the 'valid_time' column assists in retrieving the correct price
   for the product on June 15, 2023, even if the price has changed multiple times in
   the past.

   The 'valid_time' column thus empowers developers to perform precise temporal
   queries and navigate through historical data with ease, making it a valuable
   tool in bi-temporal data management.
*/

/*
   Developer's Documentation for 'decision_time'

   The 'decision_time' column within the 'bi_temporal_base_table' is a crucial
   element in bi-temporal data management, representing the time range during which
   decisions or changes were made regarding a specific record. This temporal
   attribute is particularly valuable when tracking and understanding the context
   of changes to data.

   For instance, consider a scenario where the 'bi_temporal_base_table' contains
   records for employee promotions within a company. In this context, 'decision_time'
   would denote the period during which the promotion decision was made. If an HR
   analyst wishes to identify all employees who received promotions during a specific
   quarter, they can utilize 'decision_time' to filter records based on this timeframe.

   Example Query:
   SELECT employee_name
   FROM bi_temporal_base_table
   WHERE promotion_status = 'Promoted'
   AND '2023-Q2'::tstzrange @> decision_time;

   In this example, 'decision_time' assists in isolating the promotion decisions
   made during the second quarter of 2023.

   The 'decision_time' column is a valuable tool for developers to comprehend and
   analyze changes within the temporal context of their data. It enables precise
   querying of records affected by specific decisions or events, enhancing the
   utility of bi-temporal data management.
*/

/*
   Developer's Documentation for Interaction between 'valid_time' and 'decision_time'

   The 'valid_time' and 'decision_time' columns within the 'bi_temporal_base_table'
   collectively facilitate a comprehensive understanding of the temporal aspects of
   data changes and decisions. The interaction between these columns is instrumental
   in scenarios where it is essential to discern not only when a record is valid but
   also when decisions were made that influenced its validity.

   Consider a scenario where the 'bi_temporal_base_table' contains records for
   contract agreements. 'valid_time' represents the period during which a contract
   is considered valid, while 'decision_time' indicates when a decision or change
   was made regarding that contract. By examining both attributes together, users can
   derive valuable insights. For instance, to identify contracts that were extended
   during a specific month and understand when those extensions were decided, one
   can use a query like this:

   Example Query:
   SELECT contract_id, valid_time, decision_time
   FROM bi_temporal_base_table
   WHERE contract_status = 'Extended'
   AND '2023-05-01'::timestamptz <@ valid_time
   AND '2023-05-01'::timestamptz <@ decision_time;

   In this example, the query extracts contracts that were extended in May 2023 and
   provides the 'valid_time' (the period of validity) and 'decision_time' (the time
   the extension decision was made) for each of those contracts.

   The interplay between 'valid_time' and 'decision_time' empowers developers to
   explore the temporal dimensions of data, enabling precise queries that reveal not
   only the current state but also the historical decision-making context. It is a
   powerful feature for comprehensive bi-temporal data management.
*/

create table bi_temporal_base_table
(
    id            bigint default nextval('business_key_seq'),
    row_id        bigint default nextval('row_id_seq'),
    valid_time    tstzrange default ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange,
    decision_time tstzrange default ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange,
    db_tx_time    tstzrange default ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange,
    primary key (id, row_id)
);

-- Separator
-----------------------------------------------------

/*
   Developer's Explanation of Vertex Identification

   In our graph database, each vertex is uniquely identified by two key attributes:
   'vertex_id' and 'vertex_type.' These attributes play a crucial role in organizing
   and accessing data within the graph structure. 

   - 'vertex_id' is an essential identifier for vertices and is represented as a
     universally unique identifier (UUID). This ensures that each vertex has a
     globally unique identity across the entire database. UUIDs are particularly
     valuable when it comes to linking and referencing vertices in a distributed or
     decentralized environment.

   - 'vertex_type' complements 'vertex_id' by providing a means to categorize and
     classify vertices. It is represented as an integer and allows us to assign a
     specific type or label to each vertex. This typing mechanism is vital for
     differentiating vertices based on their roles or characteristics within the
     graph.

   Together, 'vertex_id' and 'vertex_type' create a powerful combination for
   vertex identification and classification. This approach not only ensures
   uniqueness and consistency but also enables efficient querying and traversal
   within the graph database, making it a fundamental aspect of our data modeling
   strategy.
*/

/*
   Developer's Documentation for 'vertex_id' Association

   In our data model, the "vertex_id" attribute is not directly stored within the
   "article" table. Instead, it is managed through association in the "uuid_lookup"
   table, creating a relationship between the "vertex_id" and the "article id."

   This design choice offers several advantages in terms of data organization and
   maintainability:

   1. Uniqueness: The "uuid_lookup" table ensures that each "vertex_id" is uniquely
      associated with an "article id." This guarantees that every article has a
      corresponding and distinct "vertex_id," preventing any ambiguity or conflicts
      in the association.

   2. Centralized Management: By centralizing the management of "vertex_id" in the
      "uuid_lookup" table, we establish a single point of reference for all vertices
      used throughout the system. This enhances data integrity and simplifies
      maintenance, as any updates or changes to "vertex_id" associations can be
      managed centrally.

   3. Efficient Querying: This association allows for efficient querying of articles
      based on their associated vertices. Developers can retrieve articles linked to
      specific vertices by querying the "uuid_lookup" table, which provides a clear
      mapping between "vertex_id" and "article id."

   To retrieve the "vertex_id" associated with an article, developers can query the
   "uuid_lookup" table using the article's "id." This operation ensures that each
   article is associated with a specific "vertex_id," allowing for precise vertex
   referencing in our graph database.

   Example Query:
   SELECT vertex_id
   FROM uuid_lookup
   WHERE business_key = 'article_id';

   In this query, substituting 'article_id' with the desired article's identifier
   will return the corresponding "vertex_id."

   This association mechanism simplifies vertex management, enhances data consistency,
   and supports efficient graph-based queries within our system.
*/

/*
   Developer's Documentation for Table 'article'

   The 'article' table represents a crucial aspect of our data model, extending the
   bi-temporal base table for specific data related to articles. This table includes
   several attributes that provide detailed information about articles, such as
   'article_id,' 'description_1,' 'description_2,' 'match_code,' 'long_text,' and
   'article_group.' These fields serve to characterize and categorize articles based
   on their attributes.

   - 'article_id': This is a unique identifier for each article, represented as text.
     It is a critical reference point for identifying individual articles within our
     system.
   
     The 'article_id' is copied from an external 'mms' (SAGE).

   - 'description_1' and 'description_2': These fields capture textual descriptions
     of the article. They are essential for providing additional details and context
     about each article.
   
     The 'description_1' is copied from an external 'mms' (SAGE).

   - 'match_code': This field is used to define a code that aids in matching or
     categorizing articles based on specific criteria.

     The 'match_code' is copied from an external 'mms' (SAGE).

   - 'long_text': This attribute is designed to store extensive textual information
     related to an article, making it a valuable resource for storing comprehensive
     descriptions or content.

     The 'long_text' is copied from an external 'mms' (SAGE).

   - 'article_group': It classifies articles into specific groups or categories,
     allowing for organized grouping and querying of related articles.

     The 'article_group' is copied from an external 'mms' (SAGE).

   Additionally, the 'article' table leverages two key attributes, 'vertex_id' and
   'vertex_type,' as described in our documentation. 'vertex_id' serves as a unique
   identifier for vertices within our graph database, while 'vertex_type' provides
   a means to categorize these vertices based on their roles or characteristics.

   By combining these attributes with the bi-temporal base table's temporal aspects,
   the 'article' table enhances our data model, enabling the effective management
   and querying of article-related information within our system.
*/

create table article
(
    like bi_temporal_base_table including all,
    article_id    text not null,
    description_1 text not null,
    description_2 text,
    match_code    text not null,
    long_text     text not null,
    article_group text not null,

    vertex_type   int
);

/*
   Function Documentation for rt_article_append

   The 'rt_article_append' function is designed to append or update article records
   within our system, associating them with vertex identifiers in a graph database.
   This function plays a vital role in managing articles, ensuring their uniqueness
   and consistency while maintaining a connection to vertices in our graph data model.

   Parameters:
   - 'p_article_id' (text): The unique identifier for the article being appended or
     updated.
   - 'p_description_1' (text): The first description associated with the article.
   - 'p_description_2' (text): The second description associated with the article.
   - 'p_match_code' (text): A match code for categorizing the article.
   - 'p_long_text' (text): A long-form text description of the article.
   - 'p_article_group' (text): The group to which the article belongs.
   - 'p_vertex_id' (uuid): The identifier of the vertex associated with the article
     in our graph database.
   - 'p_vertex_type' (int): An integer indicating the type of vertex associated with
     the article.

   Function Behavior:
   - The function begins by querying the 'article' table to check if an article with
     the specified 'p_article_id' already exists.
   - If no matching article is found, a new article is created and associated with
     the provided 'p_vertex_id.'
   - The function ensures the uniqueness of articles based on their content. If the
     content of the existing article matches the provided parameters, no updates
     are made.
   - If the content differs, the existing article's 'db_tx_time' is updated to
     indicate the time range during which the modification occurred.
   - A new version of the article is inserted with updated 'valid_time' and 'db_tx_time'
     to represent the latest state.
   - The function returns the 'p_vertex_id' to maintain the association between the
     article and the graph database.

   Example Usage:
   - To append or update an article:
     SELECT rt_article_append('unique_id', 'desc1', 'desc2', 'code', 'text', 'group', 'vertex_id', 1);

   This function is essential for maintaining the integrity of articles and their
   associations with vertices, ensuring efficient management within our graph data model.
*/
create or replace function rt_article_append(
    p_article_id text,
    p_description_1 text,
    p_description_2 text,
    p_match_code text,
    p_long_text text,
    p_article_group text,
    p_vertex_id uuid,
    p_vertex_type int
)
    returns uuid
as $$
declare
    business_key         bigint;
    article_instance     article%rowtype;
    article_instance_md5 uuid;
    parameter_md5        uuid;
begin
    select *
    from article
    where article_id = p_article_id
    order by row_id desc
    limit 1
    into article_instance;

    if not found then
        business_key := associate_business_key(p_vertex_id);

        insert into article (id, article_id, description_1, description_2, match_code, long_text, article_group, vertex_type)
        values (business_key, p_article_id, p_description_1, p_description_2, p_match_code, p_long_text, p_article_group, p_vertex_type);

        return p_vertex_id;
    end if;

    article_instance_md5 = md5(
            cast(
                    (article_instance.article_id || article_instance.description_1 || article_instance.description_2 ||
                     article_instance.match_code || article_instance.long_text || article_instance.article_group) as text)
        )::uuid;

    parameter_md5 = md5(
            cast((p_article_id || p_description_1 || p_description_2 || p_match_code || p_long_text || p_article_group) as text)
        )::uuid;

    if (article_instance_md5 = parameter_md5) then
        return p_vertex_id;
    end if;

    update article
    set db_tx_time = ('[' || (lower(article_instance.db_tx_time)) || ', ' || (now() at time zone 'utc') || ' )')::tstzrange
    where row_id = article_instance.row_id;

    article_instance.db_tx_time := ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange;
    article_instance.valid_time := ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange;
    article_instance.row_id = nextval('row_id_seq');

    insert into article (id, article_id, description_1, description_2, match_code, long_text, article_group, vertex_type)
    values (article_instance.id, p_article_id, p_description_1, p_description_2, p_match_code, p_long_text, p_article_group, p_vertex_type);

    return p_vertex_id;
end
$$ language plpgsql;

/*
   Table Documentation for 'article_supplier'

   The 'article_supplier' table is designed to manage and maintain relationships
   between articles and their multiple suppliers within our data model. Each entry
   in this table represents a supplier's association with a specific article. This
   table allows us to efficiently track supplier-specific information for articles,
   including purchase details and pricing information.

   Column Definitions:
   - 'article_id' (text): The unique identifier of the article associated with the
     supplier. This is a required field.

     The 'article_id' is copied from an external 'mms' (SAGE).
   
   - 'supplier_id' (text): The unique identifier of the supplier. This is a required
     field.

     The 'supplier_id' is copied from an external 'mms' (SAGE).

   - 'description_1' (text): The name or description of the article as provided by
     the supplier. This is a required field.

     The 'description_1' is copied from an external 'mms' (SAGE).

   - 'description_2' (text): Additional description or details about the article
     provided by the supplier. This is a required field.

     The 'description_2' is copied from an external 'mms' (SAGE).

   - 'purchase_unit' (text): Indicates the unit of measurement for the article's
     purchase, which can be 'kg' or 'liter.' This is a required field.

     The 'purchase_unit' is copied from an external 'mms' (SAGE).

   - 'purchase_price' (numeric): The price of the article in euros. This is a
     required field.

     The 'purchase_price' is copied from an external 'mms' (SAGE).

   - 'vertex_type' (int): An integer indicating the type of vertex associated with
     the article supplier.

   Purpose:
   The 'article_supplier' table enables us to maintain detailed records of articles
   sourced from various suppliers. It allows us to efficiently manage information
   about article names, descriptions, purchase units, and prices, facilitating
   procurement processes, supplier relationships, and price tracking.

   Example Usage:
   - To record a new article-supplier association:
     INSERT INTO article_supplier (article_id, supplier_id, description_1, description_2, purchase_unit, purchase_price, vertex_type)
     VALUES ('article123', 'supplier456', 'Product A', 'High-quality product', 'kg', 10.99, 1);

   This table supports the management of supplier-specific data for articles, helping
   us streamline procurement operations and maintain accurate pricing information.
*/

create table article_supplier
(
    like bi_temporal_base_table including all,
    article_id     text not null,
    supplier_id    text not null,
    description_1  text not null,
    description_2  text,
    purchase_unit  text not null,
    purchase_price numeric not null,
    vertex_type      int not null
);

/*
   Function Documentation for 'rt_article_supplier_append'

   This function, 'rt_article_supplier_append,' is designed to manage associations
   between articles and their suppliers. It allows for the addition of supplier
   information for articles and handles updates based on changes in supplier
   data. The function ensures the integrity of supplier associations and
   supports bi-temporal data management.

   Parameters:
   - 'p_article_id' (text): The unique identifier of the article associated with
     the supplier. This parameter is required.
   - 'p_supplier_id' (text): The unique identifier of the supplier. This parameter
     is required.
   - 'p_description_1' (text): The name or description of the article as provided
     by the supplier. This parameter is required.
   - 'p_description_2' (text): Additional description or details about the article
     provided by the supplier. This parameter is required.
   - 'p_purchase_unit' (text): Indicates the unit of measurement for the article's
     purchase, which can be 'kg' or 'liter.' This parameter is required.
   - 'p_purchase_price' (numeric): The price of the article in euros. This parameter
     is required.
   - 'p_vertex_id' (uuid): The unique identifier for the vertex associated with the
     supplier-article relationship. This parameter is required.
   - 'p_vertex_type' (int): An integer indicating the type of vertex associated with
     the article supplier. This parameter is required.

   Function Logic:
   - The function first attempts to retrieve the latest record in 'article_supplier'
     with matching 'article_id' and 'supplier_id.' If no matching record is found,
     a new record is created with the provided parameters.
   - If a matching record is found, the function compares the MD5 hash of the existing
     record's data with the MD5 hash of the input parameters. If they match, the function
     returns the 'p_vertex_id' without making any changes.
   - If the MD5 hashes do not match, the function updates the existing 'article_supplier'
     record to reflect the new 'db_tx_time,' 'valid_time,' and 'row_id.' It then inserts
     a new record with the updated information, ensuring the preservation of historical
     data.

   Example Usage:
   - To associate a supplier with an article:
     SELECT rt_article_supplier_append(
        'article123', 'supplier456', 'Product A', 'High-quality product', 'kg', 10.99, 'vertex123', 1
     );

   This function supports the management of supplier-article associations while maintaining
   historical data integrity.
*/
create or replace function rt_article_supplier_append(
    p_article_id text,
    p_supplier_id text,
    p_description_1 text,
    p_description_2 text,
    p_purchase_unit text,
    p_purchase_price numeric,
    p_vertex_id uuid,
    p_vertex_type int
)
    returns uuid
as $$
declare
    business_key                  bigint;
    article_supplier_instance     article_supplier%rowtype;
    article_supplier_instance_md5 uuid;
    parameter_md5                 uuid;
begin
    select *
    from article_supplier
    where article_id = p_article_id and supplier_id = p_supplier_id
    order by row_id desc
    limit 1
    into article_supplier_instance;

    if not found then
        business_key := associate_business_key(p_vertex_id);

        insert into article_supplier (id, article_id, supplier_id, description_1, description_2, purchase_unit, purchase_price, vertex_type)
        values (business_key, p_article_id, p_supplier_id, p_description_1, p_description_2, p_purchase_unit, p_purchase_price, p_vertex_type);

        return p_vertex_id;
    end if;

    article_supplier_instance_md5 = md5(
            cast(
                    (article_supplier_instance.article_id || article_supplier_instance.supplier_id ||
                     article_supplier_instance.description_1 || article_supplier_instance.description_2 ||
                     article_supplier_instance.purchase_unit || article_supplier_instance.purchase_price) as text))::uuid;

    parameter_md5 = md5(
            cast(
                    (p_article_id || p_supplier_id || p_description_1 || p_description_2 || p_purchase_unit || p_purchase_price) as text))::uuid;

    if (article_supplier_instance_md5 = parameter_md5) then
        return p_vertex_id;
    end if;

    update article_supplier
    set db_tx_time = ('[' || (lower(article_supplier_instance.db_tx_time)) || ', ' || (now() at time zone 'utc') || ' )')::tstzrange
    where row_id = article_supplier_instance.row_id;

    article_supplier_instance.db_tx_time := ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange;
    article_supplier_instance.valid_time := ('[' || (now() at time zone 'utc') || ', infinity)')::tstzrange;
    article_supplier_instance.row_id = nextval('row_id_seq');

    insert into article_supplier (id, article_id, supplier_id, description_1, description_2, purchase_unit, purchase_price, vertex_type)
    values (article_supplier_instance.id, p_article_id, p_supplier_id, p_description_1, p_description_2, p_purchase_unit, p_purchase_price, p_vertex_type);

    return p_vertex_id;
end
$$ language plpgsql;

-- Set the version in the key/value store
SELECT * FROM rt_set_key_value('refractory.schema.version', 'v1000');

-- Commit the transaction
COMMIT;
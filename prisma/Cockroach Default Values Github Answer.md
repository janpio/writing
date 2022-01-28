-   [Answer to Cockroach Default Value
    Handling](#answer-to-cockroach-default-value-handling)

# Answer to Cockroach Default Value Handling

Issue: <https://github.com/prisma/prisma/issues/11167>

This problem is visible in my testing. First of all, while introspecting
the database, we get this weird default value of
`@default(dbgenerated("'active':::STRING::VARCHAR))`. Functionally, it's
a completely unnecessary cast.

First, we should test how it works locally. Creating the following DDL:

``` sql
CREATE TABLE foo (
    id INT PRIMARY KEY,
    one VARCHAR(255) DEFAULT 'active',
    two STRING DEFAULT 'active'
)
```

This is correcly introspected to:

``` prisma
model foo {
  id  Int    @id
  one String @default("active") @db.VarChar(255)
  two String @default("active")
}
```

The second thing to find out is what actually is written to the
introspection CI DDL. We get the connection string from the
introspection output. Using it to connect to the database, we'll see the
schema with the following SQL:

``` sql
SELECT * FROM information_schema.columns
WHERE table_name = 'access_tokens'
AND column_name = 'workflow_state';
```

Which returns:

``` text
-[ RECORD 1 ]------------+---------------------------
table_catalog            | canvas-lms
table_schema             | public
table_name               | access_tokens
column_name              | workflow_state
ordinal_position         | 14
column_default           | 'active':::STRING::VARCHAR
is_nullable              | NO
data_type                | character varying
```

So the default is actually `'active':::STRING::VARCHAR` and the
introspection does the right thing by rendering it as `dbgenerated` with
all additional casts. If the user doesn't want this, they can change the
it to `@default("active")` and create a migration to change this (when
migrations work, naturally).

The last interesting thing to check out is how this column was created
originally. We see the original DDL in our [database schema
repository](https://github.com/prisma/database-schema-examples/blob/8cea37d834f3effd6aad53e98c5bc865b4d85335/postgres/canvas-lms/schema.sql#L232).
Here the interesting part is:

``` sql
workflow_state character varying DEFAULT 'active'::character varying NOT NULL
```

So, for whatever reason CockroachDB does a different cast when we set
the default value.

Summary:

-   If we migrate a default string value without a cast, it will
    introspect as a default string value without a cast.
-   Our introspection Cockroach databases have some defaults with a cast
-   The cast is different from what was given when we created the table
    in this case.

Not our bug this time.

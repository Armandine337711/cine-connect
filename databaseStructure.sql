BEGIN;
-- Regex

DROP EXTENSION IF EXISTS unaccent CASCADE;

CREATE EXTENSION unaccent;

DROP DOMAIN IF EXISTS TEXT_ONLY, ALPHANUM, TEXT_MAIL, TEXT_CP, TEXT_PWD CASCADE;

CREATE DOMAIN TEXT_ONLY AS TEXT CHECK(unaccent(VALUE) ~ '^[A-Za-z \-]+$');
CREATE DOMAIN ALPHANUM AS TEXT CHECK(unaccent(VALUE) ~ '^[A-Za-z\.\ \-\#\d]+$');
CREATE DOMAIN TEXT_MAIL AS TEXT CHECK(VALUE ~ '(^[a-z\d\.\-\_]+)@{1}([a-z\d\.\-]{2,})[.]([a-z]{2,5})$');
CREATE DOMAIN TEXT_CP AS TEXT CHECK (VALUE ~ '(?!^00)\d{5}$');
CREATE DOMAIN TEXT_PWD AS TEXT CHECK (VALUE ~ '^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[-+!*$@%_])([-+!*$@%_\w]{8,})$');

-- Tables creation

DROP TABLE IF EXISTS "cinema", "projection_room", "movie", "client", "price", "payment", "session", "booking" CASCADE;

CREATE TABLE IF NOT EXISTS "cinema"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"name" ALPHANUM NOT NULL UNIQUE, 
"address" ALPHANUM NOT NULL,
"zip" TEXT_CP NOT NULL,
"city" TEXT_ONLY NOT NULL
);

CREATE TABLE IF NOT EXISTS "projection_room"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"room_name" ALPHANUM NOT NULL,
"seat_quantity" INT NOT NULL,
"cinema_id" INT NOT NULL REFERENCES "cinema"("id")
);

CREATE TABLE IF NOT EXISTS "movie"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"title" ALPHANUM NOT NULL UNIQUE,
"director" TEXT_ONLY NOT NULL,
"year" INT NOT NULL,
"duration" TIME NOT NULL 
);

CREATE TABLE IF NOT EXISTS "client"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"firstname" TEXT_ONLY NOT NULL,
"lastname" TEXT_ONLY NOT NULL,
"email" TEXT_MAIL NOT NULL UNIQUE,
"password" TEXT_PWD NOT NULL
);

CREATE TABLE IF NOT EXISTS "price"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"category" TEXT NOT NULL UNIQUE,
"amount" FLOAT NOT NULL
);

CREATE TABLE IF NOT EXISTS "payment"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"entitled" TEXT_ONLY NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS "session"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"movie_id" INT NOT NULL REFERENCES "movie"("id"),
"projection_room_id" INT NOT NULL REFERENCES "projection_room"("id"),
"date_time" TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS "booking"(
"id" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
"client_id" INT NOT NULL REFERENCES "client"("id"),
"session_id" INT NOT NULL REFERENCES "session"("id"),
"price_id" INT NOT NULL REFERENCES "price"("id"),
"nb_seat" INT NOT NULL,
"payment_id" INT NOT NULL REFERENCES "payment"("id")
);

-- basic datas 

TRUNCATE TABLE "price" RESTART IDENTITY CASCADE;
TRUNCATE TABLE "payment" RESTART IDENTITY CASCADE;

INSERT INTO "price"("category", "amount") VALUES
('Plein tarif', 9.20),
('Etudiant', 7.60),
('Moins de 14 ans', 5.90);

INSERT INTO "payment"("entitled") VALUES
('CB'),
('Virement'),
('Sur place');


---------------------------------------------------
-- VIEWS AND FUNCTIONS
---------------------------------------------------
DROP VIEW IF EXISTS "session_list", "available_seats", "room_list" CASCADE;


-- VIEW liste des salles rattachées à leur cinema
CREATE VIEW "rooms_list" AS
SELECT c."id" AS cinema_id,
       c."name",
       pr."room_name",
       pr."id" as projection_room_id,
       pr."seat_quantity"
    FROM cinema c
    JOIN projection_room pr ON pr."cinema_id" = c."id";


--VIEW available places


CREATE VIEW "available_seats" AS
SELECT s."id" AS "session_id",
        pr."seat_quantity",
        (pr."seat_quantity" -
        (CASE WHEN SUM(b."nb_seat") IS NULL
                THEN 0
                ELSE SUM(b."nb_seat") END)) AS "remaining_seats"
    FROM "session" s
    LEFT OUTER JOIN "projection_room" pr ON pr."id" = s."projection_room_id"
    LEFT OUTER JOIN "booking" b on b."session_id" = s."id"
    GROUP BY s."id",
            pr."seat_quantity";

-- Liste des films programmés

CREATE VIEW "session_list" AS
SELECT s."id",
       c."name",
       c."city",
       pr."room_name",
       m."title",
       m."director",
       m."year",
       to_char(DATE(s."date_time"), 'DD/MM/YYYY') AS "diffusion_date",
       date_trunc('minute',s."date_time" - "date_trunc"('day', s."date_time")) as "begin_hour",
       (date_trunc('minute',s."date_time" - "date_trunc"('day', s."date_time")) + m."duration") AS "end_hour",
       avs."remaining_seats" 
    FROM session s 
    JOIN "projection_room" pr ON pr.id = s."projection_room_id"
    JOIN "cinema" c ON c."id" = pr."cinema_id"
    JOIN "movie" m ON s."movie_id" = m."id"
    JOIN "available_seats" avs on avs."session_id" = s."id"
    GROUP BY s.id,
       c."name",
       c."city",
       pr."room_name",
       m."title",
       m."director",
       m."year",
       m."duration",
       pr."seat_quantity",
       avs."remaining_seats"
    ORDER BY s."date_time";

-- FUNCTIONS

DROP FUNCTION IF EXISTS "new_movie", "new_session", "new_client", "new_booking" CASCADE;

---- add a session
CREATE FUNCTION "new_movie"("title" ALPHANUM, "director" TEXT_ONLY, "year" INT, "duration" TIME) RETURNS SETOF movie AS
$$
INSERT INTO "movie"("title", "director", "year", "duration") VALUES ($1, $2, $3, $4) RETURNING *;
$$
LANGUAGE sql VOLATILE STRICT;

--- add a session
CREATE FUNCTION "new_session"("movie_id" INT, "projection_room_id" INT, "date_time" TIMESTAMPTZ) RETURNS SETOF session AS
$$
INSERT INTO "session"("movie_id", "projection_room_id", "date_time") VALUES ($1, $2, $3) RETURNING *;
$$
LANGUAGE sql VOLATILE STRICT;

--- add a client
CREATE FUNCTION "new_client"("firstname" TEXT_ONLY, "lastname" TEXT_ONLY, "email" TEXT_MAIL, "pwd" TEXT_PWD) RETURNS SETOF client AS
$$
INSERT INTO "client"("firstname", "lastname", "email", "password") VALUES ($1, $2, $3, $4) RETURNING *
$$
LANGUAGE sql VOLATILE STRICT;

-- --- add a booking
CREATE OR REPLACE FUNCTION "new_booking"("client_id" INT, "session_id" INT, "price_id" INT, "nb_seat" INT, "payment_id" INT) RETURNS TEXT AS
$$
DECLARE 
    total_price FLOAT;
    remaining_seats INTEGER;
    sentence TEXT;
BEGIN

-- Verifying remaining seats
    SELECT (ast."seat_quantity") INTO remaining_seats
        FROM "available_seats" ast
        WHERE ast."session_id" = $2;
        
    IF ($4 > remaining_seats) THEN
        sentence := 'Pas assez de places disponibles. Choisissez une autre séance.';
    ELSE

        INSERT INTO "booking"("client_id", "session_id", "price_id", "nb_seat", "payment_id") VALUES ($1, $2, $3, $4, $5);
        SELECT (p."amount" * $4) INTO total_price
            FROM price p
            WHERE p.id  = price_id;
        sentence := 'Montant à payer : ' || (total_price::float)::text || ' €';
    END IF;
    RETURN sentence;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

---------------------------------------------------
-- LES ROLES DES UTILISATEURS BACKEND
---------------------------------------------------
--  1 create schemas
-- CREATE SCHEMA "admin";

-- CREATE SCHEMA "the_movie";
-- ALTER TABLE "movie" SET SCHEMA "the_movies";
-- ALTER FUNCTION "new_session" SET SCHEMA "the_movies";

-- CREATE SCHEMA "the_client";
-- ALTER FUNCTION "new_booking" SET SCHEMA "the_client";


-- CREATE ROLE "database_manager";
-- CREATE ROLE "complex_manager";
-- CREATE ROLE "client";

-- GRANT ALL ON ALL TO "database_manager";
-- GRANT SELECT ON ALL TABLES TO "complex_manager";
-- GRANT SELECT ON ALL TABLES TO "client";

COMMIT;
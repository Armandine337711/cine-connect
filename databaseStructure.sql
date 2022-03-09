BEGIN;
-- Regex

DROP EXTENSION IF EXISTS unaccent CASCADE;

CREATE EXTENSION unaccent;

DROP DOMAIN IF EXISTS TEXT_ONLY, ALPHANUM, TEXT_MAIL, TEXT_CP, TEXT_PWD CASCADE;

CREATE DOMAIN TEXT_ONLY AS TEXT CHECK(unaccent(VALUE) ~ '^[A-Za-z \-]+$');
CREATE DOMAIN ALPHANUM AS TEXT CHECK(unaccent(VALUE) ~ '^[A-Za-z\ \-\#\d]+$');
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
--VIEW available places
DROP VIEW IF EXISTS session_list CASCADE;
DROP VIEW IF EXISTS available_seats CASCADE;

CREATE VIEW available_seats AS
SELECT s.id AS session_id,
        (pr.seat_quantity -
        (CASE WHEN SUM(b.nb_seat) IS NULL
                THEN 0
                ELSE SUM(b.nb_seat) END)) AS remaining_seats
    FROM "session" s
    LEFT OUTER JOIN projection_room pr ON pr.id = s.projection_room_id
    LEFT OUTER JOIN booking b on b.session_id = s.id
    GROUP BY s.id,
            pr.seat_quantity;

-- Liste des films programmés

CREATE VIEW session_list AS
SELECT s.id,
       c.name,
       c.city,
       pr.room_name,
       m.title,
       m.director,
       m.year,
       to_char(DATE(s.date_time), 'DD/MM/YYYY') AS "diffusion_date",
       date_trunc('minute',s.date_time - date_trunc('day', s.date_time)) as begin_hour,
       (date_trunc('minute',s.date_time - date_trunc('day', s.date_time)) + m.duration) AS end_hour,
       avs.remaining_seats 
    FROM session s 
    JOIN projection_room pr ON pr.id = s.projection_room_id
    JOIN cinema c ON c.id = pr.cinema_id
    JOIN movie m ON s.movie_id = m.id
    JOIN available_seats avs on avs.session_id = s.id
    GROUP BY s.id,
       c.name,
       c.city,
       pr.room_name,
       m.title,
       m.director,
       m.year,
       m.duration,
       (pr.seat_quantity),
       avs.remaining_seats;


COMMIT;
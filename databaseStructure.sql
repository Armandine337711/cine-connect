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
"duration (mn)" INT NOT NULL 
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



COMMIT;
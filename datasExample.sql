BEGIN;

TRUNCATE TABLE "cinema", "projection_room", "movie", "client", "session", "booking" RESTART IDENTITY CASCADE;

INSERT INTO "cinema"("name", "address", "zip", "city") VALUES
('Cap Cinema', 'Zone industrielle du Pont Rouge', '11300', 'Carcassonne'),
('Elysée', '9 allée des Maronniers', '11300', 'Limoux'),
('Veo', '21 boulevard Lapasset', '11400', 'Castelnaudary');

INSERT INTO "projection_room"("room_name", "seat_quantity", "cinema_id") VALUES
('salle 1', 456, 1),
('Salle 2', 301, 1),
('Salle 3', 254, 1),
('Salle 1', 250, 2),
('Salle A', 200, 3);

INSERT INTO "movie"("title", "director", "year", "duration") VALUES
('Maison de retraite', 'Thomas Gilou', 2022, '01:37'),
('Zaï Zaî Zaï Zaî', 'François Desagnat', 2022, '01:22'),
('Mort sur le Nil', 'Kenneth Branagh', 2022, '02:07');

INSERT INTO "client"("firstname", "lastname", "email", "password") VALUES
('Mickey', 'Mouse', 'mickey@mail.fr', 'Mdp@145zer+'),
('Donald', 'Duck', 'donald@mail.fr', 'Fojfin$fregv1486');

INSERT INTO "session"("movie_id", "projection_room_id", "date_time") VALUES
(1, 3, '2022-03-26 20:30:00'),
(1, 1, '2022-03-26 20:30:00'),
(1, 2, '2022-03-26 20:30:00'),
(2, 4, '2022-04-01 17:30:00'),
(3, 5, '2022-03-28 10:30:00');

INSERT INTO "booking"("client_id", "session_id", "price_id", "nb_seat", "payment_id") VALUES
(1, 1, 1, 2, 1),
(1, 1, 2, 1, 1),
(1, 1, 3, 3, 1),
(2, 5, 1, 5, 3);


COMMIT;
# CINEMA CONNECT

Dans le cadre d'un exercice, il s'agit ici de créer une base de données en vue de la création d'un site de réservation de places d'une corporation de cinemas.

## Installation

Le SGDBR choisit est PostgreSQL. La programmation a été testée sur la v14.

```bash
git clone git@github.com:Armandine337711/cine-connect.git
cd cine-connect
```

-> créer la db
    se connecter en root sur son serveur :
    `sudo -i -u postgre`
    puis
    `CREATE DATABASE [NomBase];`
Remplacer [NomBase] par le nom souhaité de la base de données
    
-> installer databaseStructure.sql
-> installer des données d'exemple

## Requetes

### Listes

des cinémas et salles de projection -> `SELECT * FROM "rooms_list";`
des clients -> `SELECT * FROM "client";`
des films -> `SELECT * FROM "movie"`
des tarifs -> `SELECT * FROM "price";`
des moyens de paiement -> `SELECT * FROM payment;`

des séances avec le nombre de places disponibles -> `SELECT * FROM "session_list";`
des cinémas et des salles de projection -> `SELECT * FROM "rooms_list";`

### Nouveau film

```sql
SELECT "new_movie"('[titre]', '[realisateur]', [Année de sortie], '[duree au format hh:mm]');
SELECT "new_movie"('E.T.', 'Steven Spielberg', 1982, '01:55');
```

### Nouvelle séance

Pour cela il est nécessaire d'afficher la `room_list` (voir plus haut) et la liste des films pour récupérer les id nécessaires

```sql
SELECT "new_session"([movie_id], [projection_room_id], '[date au format YYYY-MM-DD HH:MM]');
SELECT "new_session"(4, 3, '2022-03-30 14:00');
```

### Nouveau client

```sql
SELECT "new_client"('Marie', 'Aristocats', 'marie@mail.fr', 'Mycatsare_3');
SELECT "new_client"('[firstname]', '[lastname]', '[email]', '[password]');
```
### Nouvelle réservation

```sql
SELECT "new_booking"([client_id], [session_id], [price_id], [nb_seat], [payment_id]);
SELECT "new_booking"(3, 6, 2, 4, 3);
```
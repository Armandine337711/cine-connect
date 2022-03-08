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

### Liste des cinémas

```sql
SELECT * FROM "cinema";
```

### Liste des films programmés 


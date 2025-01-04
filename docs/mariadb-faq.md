# Change root password in MariaDB Docker container running with docker-compose

Override the entrypoint in docker-compose.yml for the MariaDB Docker container by adding:

    entrypoint: mysqld_safe --skip-grant-tables --user=mysql

The start up the Docker Compose stack:

    $> docker-compose up -d
  
Then login to the Docker container:

    $> sudo docker exec -ti docker-container-name bash

And login as root without password:

    $> mysql -u root -p

Change the root password in mysql cli:

    mysql> FLUSH PRIVILEGES;
    mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_secret';
    mysql> FLUSH PRIVILEGES;
    
Logout of mysql and the Docker container (2x exit), remove the entrypoint line from the docker-compose.yml and reload the Docker Composer stack:

    $> docker-compose up -d
    
You can now login to the MariaDB container and connect to the database with the new root password:

    $> sudo docker exec -ti docker-container-name bash
    $> mysql -u root -p

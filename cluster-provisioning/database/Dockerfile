# database/Dockerfile
FROM postgis/postgis:latest
COPY ./initdb.sh /docker-entrypoint-initdb.d/initdb.sh
COPY ./schemas /docker-entrypoint-initdb.d/schemas
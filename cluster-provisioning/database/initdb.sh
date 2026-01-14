#!/bin/bash
set -e

# Configuración
POSTGRES_USER="${POSTGRES_USER:-postgres}"
SCHEMAS_DIR="/docker-entrypoint-initdb.d/schemas"
DB_PREFIX="db_"  # Puedes cambiar a "ms_" para prefijo de microservicios

echo "[INIT] Iniciando proceso de inicialización de bases de datos"

# Crear bases de datos desde variable de entorno
if [ -z "${POSTGRES_MULTIPLE_DATABASES}" ]; then
  echo "[ERROR] La variable POSTGRES_MULTIPLE_DATABASES no está definida"
  exit 1
fi

echo "[INIT] Bases de datos a crear: ${POSTGRES_MULTIPLE_DATABASES}"

# Crear cada base de datos
for db in $(echo "${POSTGRES_MULTIPLE_DATABASES}" | tr ',' ' '); do
  echo "[INIT] Creando base de datos: ${db}"
  psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" <<-EOSQL
    CREATE DATABASE ${db};
    GRANT ALL PRIVILEGES ON DATABASE ${db} TO "${POSTGRES_USER}";
EOSQL
done

# Ejecutar scripts de esquema
if [ -d "${SCHEMAS_DIR}" ]; then
  for schema_dir in ${SCHEMAS_DIR}/*; do
    if [ -d "${schema_dir}" ]; then
      schema_name=$(basename "${schema_dir}")
      db_name="${DB_PREFIX}${schema_name}"
      
      echo "[INIT] Procesando esquema: ${schema_name} -> DB: ${db_name}"
      
      # Ejecutar scripts en orden numérico
      find "${schema_dir}" -name "*.sql" -type f | sort | while read script; do
        echo "[INIT] Ejecutando script: $(basename ${script}) en ${db_name}"
        psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${db_name}" -f "${script}"
      done
    fi
  done
else
  echo "[WARN] No se encontró el directorio de esquemas: ${SCHEMAS_DIR}"
fi

# Ejecutar scripts de datos
if [ -d "${DATA_DIR}" ]; then
  for data_dir in ${DATA_DIR}/*; do
    if [ -d "${data_dir}" ]; then
      schema_name=$(basename "${data_dir}")
      db_name="${DB_PREFIX}${schema_name}"
      
      echo "[INIT] Procesando datos para: ${schema_name} -> DB: ${db_name}"
      
      # Ejecutar scripts de datos
      find "${data_dir}" -name "*-data.sql" -type f | sort | while read script; do
        echo "[INIT] Ejecutando script de datos: $(basename ${script}) en ${db_name}"
        psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${db_name}" -f "${script}"
      done
    fi
  done
else
  echo "[WARN] No se encontró el directorio de datos: ${DATA_DIR}"
fi

echo "[SUCCESS] Inicialización completada exitosamente"
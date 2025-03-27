#!/bin/bash

# Función para iniciar un servicio y esperar a que esté listo
start_service() {
    service=$1
    port=$2
    echo "Iniciando $service..."
    docker-compose -f docker/docker-compose-universidades.yaml up -d $service
    ./wait-for-it.sh localhost:$port -t 60
    echo "$service está listo."
}

# Iniciar CouchDB
start_service couchdb0.universidades.com 5984
start_service couchdb1.universidades.com 7984

# Iniciar Orderer
start_service orderer.universidades.com 7050

# Iniciar Peers
start_service peer0.madrid.universidades.com 7051
start_service peer0.bogota.universidades.com 9051

# Iniciar CLI
echo "Iniciando CLI..."
docker-compose -f docker/docker-compose-universidades.yaml up -d cli

echo "Todos los servicios han sido iniciados."

# Verificar el estado de los contenedores
docker-compose -f docker/docker-compose-universidades.yaml ps

# Esperar un poco más para asegurarse de que todo esté completamente inicializado
sleep 30

echo "La red está lista para usar."

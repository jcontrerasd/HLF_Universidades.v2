#!/bin/bash
#test_explores.sh
clear

start_service() {
    service=$1
    port=$2
    echo "Iniciando $service..."
    
    # Inicia el servicio con docker-compose
    docker-compose -f docker/docker-compose-universidades.yaml up -d $service
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31;40m"
        echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo -e "│Error al iniciar $service                                                     │"
        echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
        exit 1
    fi

    # Espera a que el servicio esté listo
    ./wait-for-it.sh localhost:$port -t 60
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31;40m"
        echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo -e "│$service no está listo en el tiempo esperado.                                 │"
        echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
        exit 1
    fi

    echo -e "\e[1;32m"
    echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
    echo -e "│$service está listo.                                        │"
    echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
    echo -e ""
}

# DETENER Y ELIMINAR LOS SERVICIOS DE DOCKER COMPOSE
echo -e "\e[1;31;40m"
echo -e "╔══════════════════════════════════════════════════════════════════════════════╗"
echo -e "║             🧨 DETENIENDO Y ELIMINANDO SERVICIOS DOCKER                      ║"
echo -e "╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"

# DETENER Y ELIMINAR LOS SERVICIOS DE DOCKER COMPOSE
echo -e "\e[1;31m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│      Deteniendo y eliminando servicios de Docker Compose...                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"

docker-compose -f docker/docker-compose-universidades.yaml down --remove-orphans
docker-compose down -v

# DETENER Y ELIMINAR TODOS LOS CONTENEDORES DE DOCKER ACTIVOS
echo -e "\e[1;31m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"  
echo -e "│           Deteniendo contenedores de Docker...                               │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
docker stop $(docker ps -a -q)
echo -e "\e[1;31m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│            Eliminando contenedores de Docker...                              │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
docker rm $(docker ps -a -q) 2>/dev/null

# LIMPIAR VOLUMENES Y REDES NO UTILIZADAS
echo -e "\e[1;31m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│            Limpiando volúmenes y redes no utilizadas...                      │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
docker volume prune --all -f
docker network prune -f

# ELIMINAR DIRECTORIOS DE ORGANIZACIONES Y ARTÍCULOS DE CANAL
echo -e "\e[1;31m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│ Eliminando directorios de organizaciones y artefactos de canal...            │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
sudo rm -rf organizations/peerOrganizations
sudo rm -rf organizations/ordererOrganizations
sudo rm -rf organizations/fabric-ca/ordererOrg/
sudo rm -rf organizations/fabric-ca/org1/
sudo rm -rf organizations/fabric-ca/org2/
sudo rm -rf organizations/fabric-ca/org3/

rm -rf channel-artifacts/
mkdir channel-artifacts

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/config
export PATH=$PATH:$(pwd)/bin

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│                   Generación de Certificados                                 │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
cryptogen generate --config=./organizations/cryptogen/crypto-config-madrid.yaml  --output="organizations"

cryptogen generate --config=./organizations/cryptogen/crypto-config-bogota.yaml  --output="organizations"

cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"

# Verifica si los directorios se crearon
if [[ -d "organizations/peerOrganizations/madrid.universidades.com" && -d "organizations/peerOrganizations/bogota.universidades.com" && -d "organizations/ordererOrganizations/universidades.com" ]]; then
    echo "Los archivos se generaron correctamente. Proceda con las siguientes instrucciones."
else
    echo "Hubo un error en la generación de archivos. Por favor, revise los logs."
    exit 1
fi

echo -e "\e[1;32;40m"
echo -e "╔══════════════════════════════════════════════════════════════════════════════╗"
echo -e "║                          INICIACIÓN DE RED                                   ║"
echo -e "╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"

echo -e "\e[1;32m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│ Iniciando...                                                                 │"
echo -e "│  🎯 docker-compose-universidades.yaml                                        │"
echo -e "│    ⇢ orderer.universidades.com                                               │"
echo -e "│    ⇢ peer0.madrid.universidades.com  ◀︎ couchdb0:5984                         │"
echo -e "│    ⇢ peer0.bogota.universidades.com  ◀︎ couchdb2:5984                         │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
# docker-compose -f docker/docker-compose-universidades.yaml up -d

#----------------------------------------------------#
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
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m"
    echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
    echo -e "│Error al iniciar CLI.                                                         │"
    echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
    exit 1
fi
 
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m"
    echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
    echo -e "│Error al verificar el estado de los contenedores.                             │"
    echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
    exit 1
fi

echo -e "\e[1;32m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│Todos los servicios han sido iniciados.                                       │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
echo -e ""
 
echo -e "\e[1;32m"
# Verificar el estado de los contenedores
docker-compose -f docker/docker-compose-universidades.yaml ps

# Esperar un poco más para asegurarse de que todo esté completamente inicializado
sleep 30

#echo -e "\e[1;32m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│La red está lista para usar.                                                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
echo -e ""
 

sudo chown -R $USER:$USER organizations

export FABRIC_CFG_PATH=${PWD}/configtx
configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel

# Verifica si el comando tuvo éxito
if [ $? -ne 0 ]; then
    echo -e "\e[1;31;40m"
    echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
    echo -e "│Error: Falló la ejecución de configtxgen.                                     │"
    echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
    exit 1
fi

# Verifica si el archivo se creó y no está vacío
if [ -f "./channel-artifacts/universidadeschannel.block" ]; then
    if [ -s "./channel-artifacts/universidadeschannel.block" ]; then
        echo -e "\e[1;32m"
        echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo -e "│OK: El bloque de génesis universidadeschannel.block se generó correctamente.  │"
        echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
        echo -e ""
    else
        echo -e "\e[1;31;40m"
        echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
        echo -e "│Error: El archivo universidadeschannel.block está vacío.                       │"
        echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
        exit 1
    fi
else
    echo "Error: No se creó el archivo universidadeschannel.block."
    exit 1
fi


export FABRIC_CFG_PATH=${PWD}/config
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key

osnadmin channel join --channelID universidadeschannel --config-block ./channel-artifacts/universidadeschannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
# Verifica si el comando tuvo éxito
if [ $? -ne 0 ]; then
    echo "Error: No se pudo unir al canal universidadeschannel."
    exit 1
fi
sleep 5

osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

export CORE_PEER_TLS_ENABLED=true
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MADRID_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051
sleep 5
peer channel join -b ./channel-artifacts/universidadeschannel.block

 
export CORE_PEER_TLS_ENABLED=true
export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BOGOTA_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051
sleep 5
peer channel join -b ./channel-artifacts/universidadeschannel.block

echo -e "\e[1;32m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│ Iniciando Explorer...                                                        │"
echo -e "│  🎯 docker-compose-.yaml                                                     │"
echo -e "│    ⇢ explorer.universidades.com                                              │"
echo -e "│    ⇢ explorerdb.universidades.com                                            │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
docker-compose up -d

# # IP PÚBLICA + PUERTO 8080
# # "id": "exploreradmin",
# # "password": "exploreradminpw"

# </></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></>
# </></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></></>
echo -e "\e[1;33;40m"
echo -e "╔══════════════════════════════════════════════════════════════════════════════╗"
echo -e "║                             INSTALANDO CHAINCODE                             ║"
echo -e "╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/config/

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│                              Versión de Peer                                 │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
peer version

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│          Empaquetando el chaincode 'registroAlumnos'...                      │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
#peer lifecycle chaincode package registroAlumnos.tar.gz --path ../fabric-samples/asset-transfer-registroAlumnos/chaincode-javascript/ --lang node --label registroAlumnos_1.0
peer lifecycle chaincode package registroAlumnos.tar.gz --path ./chaincodes/registroAlumnos/chaincode-javascript/ --lang node --label registroAlumnos_1.0

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│        Madrid: Instalando el chaincode 'registroAlumnos'...                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MadridMSP"
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode install registroAlumnos.tar.gz


echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│        Bogota: Instalando el chaincode 'registroAlumnos'...                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="BogotaMSP"
export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode install registroAlumnos.tar.gz


echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Consultando los chaincodes instalados...                                    │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"

peer lifecycle chaincode queryinstalled

# Ejecutar el comando peer lifecycle chaincode queryinstalled y capturar la salida
query_result=$(peer lifecycle chaincode queryinstalled)
# Extraer el ID del paquete utilizando grep y sed
package_id=$(echo "$query_result" | grep "Package ID:" | sed 's/.*: \([^,]*\),.*/\1/')
##copiar el ID del package, es una combinación del nombre del chaincode y el hash del contenido del código
export CC_PACKAGE_ID="$package_id"
echo $CC_PACKAGE_ID

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Madrid: Aprobando el chaincode 'registroAlumnos' para tu organización...    │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --channelID universidadeschannel --name registroAlumnos --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Bogota: Aprobando el chaincode 'registroAlumnos' para tu organización...    │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --channelID universidadeschannel --name registroAlumnos --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem


echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Verificando la preparación para el Commit el chaincode 'registroAlumnos'    │"
echo -e "│                  en el canal 'threechannel'...                               │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
peer lifecycle chaincode checkcommitreadiness --channelID universidadeschannel --name registroAlumnos --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem --output json
                  
echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Commit del chaincode 'registroAlumnos' en el canal 'universidadeschannel'   │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --channelID universidadeschannel --name registroAlumnos --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem --peerAddresses localhost:7051  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051  --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt  

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Consultando el chaincode 'registroAlumnos' después del commit en el canal   │"
echo -e "│                       'universidadeschannel'...                              │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
peer lifecycle chaincode querycommitted --channelID universidadeschannel --name registroAlumnos --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Invocando la función 'InitLedger' del chaincode 'registroAlumnos'           │"
echo -e "│                       en el canal 'universidadeschannel'...                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride  orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt  -c '{"function":"InitLedger","Args":[]}'

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│                Consultando el canal 'universidadeschannel'...                │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"

curl -X GET http://admin:adminpw@localhost:5984/universidadeschannel_ | jq .


echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│ Consultando todos los activos utilizando la función 'obtenerTodosAlumnos'    │"
echo -e "│               en el canal 'universidadeschannel'...                          │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
sleep 5
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["obtenerTodosAlumnos"]}' | jq .

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│  Invocando la función 'registrarAlumno' del chaincode 'registroAlumnos'      │"
echo -e "│                   en el canal 'universidadeschannel'...                      │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
# Solicitar los parámetros necesarios
echo -e "\e[1;33m Ingrese el ID del alumno:\e[0m"
read ALUMNO_ID

echo -e "\e[1;33m Ingrese el nombre del alumno:\e[0m"
read NOMBRE

echo -e "\e[1;33m Ingrese la universidad del alumno:\e[0m"
echo -e "\e[1;36m "
echo -e "1. Madrid"
echo -e "2. Bogotá"
read -p "Ingrese su elección (1 o 2): " eleccion

case $eleccion in
    1)
        UNIVERSIDAD="Madrid"
        ;;
    2)
        UNIVERSIDAD="Bogotá"
        ;;
    *)
        echo -e "\e[1;31mOpción no válida. Por favor, seleccione 1 para Madrid o 2 para Bogotá.\e[0m"
        exit 1
        ;;
esac
echo -e "\e[0m"

read -p "Antes del Peer"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt -c "{\"function\":\"registrarAlumno\",\"Args\":[\"$ALUMNO_ID\", \"$NOMBRE\", \"$UNIVERSIDAD\"]}"

# echo -e "\e[1;33m"
# echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
# echo -e "│  Invocando la función 'obtenerAlumno' del chaincode 'registroAlumnos'        │"
# echo -e "│                       en el canal 'universidadeschannel'...                  │"
# echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
# sleep 5
# peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com  --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt -c '{"function":"obtenerAlumno","Args":["'$ALUMNO_ID'"]}'
# echo " "
# echo " "
# echo -e "\e[1;33m"
# echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
# echo -e "│ Consultando todos los activos utilizando la función 'obtenerTodosAlumnos'    │"
# echo -e "│                       en el canal 'universidadeschannel'...                  │"
# echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
# sleep 5
# peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["obtenerTodosAlumnos"]}' | jq .


echo -e "\e[1;33m Ingrese el ID del alumno:\e[0m"
read ALUMNO_ID

echo -e "\e[1;33m Ingrese el nombre del alumno:\e[0m"
read NOMBRE

echo -e "\e[1;33m Ingrese la universidad del alumno:\e[0m"
echo -e "\e[1;36m "
echo -e "1. Madrid"
echo -e "2. Bogotá"
read -p "Ingrese su elección (1 o 2): " eleccion

case $eleccion in
    1)
        UNIVERSIDAD="Madrid"
        ;;
    2)
        UNIVERSIDAD="Bogotá"
        ;;
    *)
        echo -e "\e[1;31mOpción no válida. Por favor, seleccione 1 para Madrid o 2 para Bogotá.\e[0m"
        exit 1
        ;;
esac
echo -e "\e[0m"

peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt -c "{\"function\":\"registrarAlumno\",\"Args\":[\"$ALUMNO_ID\", \"$NOMBRE\", \"$UNIVERSIDAD\"]}"
# echo -e "\e[1;33m"
# echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
# echo -e "│  Invocando la función 'obtenerAlumno' del chaincode 'registroAlumnos'        │"
# echo -e "│                       en el canal 'universidadeschannel'...                  │"
# echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
# sleep 5
#peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.universidades.com  --tls --cafile ${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem -C universidadeschannel -n registroAlumnos --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt -c '{"function":"obtenerAlumno","Args":["'$ALUMNO_ID'"]}'

echo -e "\e[1;33m"
echo -e "┌──────────────────────────────────────────────────────────────────────────────┐"
echo -e "│ Consultando todos los activos utilizando la función 'obtenerTodosAlumnos'    │"
echo -e "│                       en el canal 'universidadeschannel'...                  │"
echo -e "└──────────────────────────────────────────────────────────────────────────────┘\e[0m"
sleep 5
peer chaincode query -C universidadeschannel -n registroAlumnos -c '{"Args":["obtenerTodosAlumnos"]}' | jq .
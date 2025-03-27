#!/bin/bash
clear

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

sudo systemctl restart docker

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
export FABRIC_CFG_PATH=${PWD}/../config
export PATH=$PATH:$(pwd)/bin
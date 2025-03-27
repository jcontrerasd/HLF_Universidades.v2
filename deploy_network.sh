# CLASE CONFIGURACIÓN DE ENTORNO

# COMPROBAR SI ESTÁ INSTALADO GIT 
sudo apt-get update
sudo apt-get install git -y
sudo apt-get install jq -y

git --version

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install node


# INSTALAR DOCKER
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
groups $USER

sudo usermod -aG docker $USER
sudo newgrp docker     

sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl enable containerd.service
sudo systemctl status docker
sudo systemctl restart docker
sudo chmod 660 /var/run/docker.sock
# CERRAR SSH Y VOLVER A INGRESAR. SIEMPRE
exit


# INSTALAR GO 
sudo apt install golang -y
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile

go version

# INSTALAR NPM
sudo apt install npm -y
 

# INSTALAR DOCKER COMPOSE
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# DESCARGA REPOSITORIO Y BINARIOS
# curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.3.2 1.5.2  (version de HLF y Verisón del CA)
 

git clone https://github.com/jcontrerasd/HLF_Universidades
cd HLF_Universidades
chmod +x hlf_universidades.sh 

#curl -sSL https://github.com/hyperledger/fabric/releases/download/v2.3.2/hyperledger-fabric-linux-amd64-2.3.2.tar.gz -o hyperledger-fabric.tar.gz
#tar -xvzf hyperledger-fabric.tar.gz

# # Descargar binarios de Hyperledger Fabric
curl -sSL https://github.com/hyperledger/fabric/releases/download/v2.5.9/hyperledger-fabric-linux-amd64-2.5.9.tar.gz -o hyperledger-fabric.tar.gz
tar -xvzf hyperledger-fabric.tar.gz

# # Descargar binarios de Fabric CA
curl -sSL https://github.com/hyperledger/fabric-ca/releases/download/v1.5.12/hyperledger-fabric-ca-linux-amd64-1.5.12.tar.gz -o hyperledger-fabric-ca.tar.gz
tar -xvzf hyperledger-fabric-ca.tar.gz 

export PATH=$PATH:$(pwd)/bin
echo 'export PATH=$PATH:$(pwd)/bin' >> ~/.profile
echo 'export PATH=$PATH:$(pwd)/config' >> ~/.profile
source ~/.profile
nvm install 16.20.2
nvm use 16.20.2
nvm alias default 16


cd chaincodes/registroAlumnos/chaincode-javascript
rm -rf node_modules package-lock.json
npm install

cd ../../..
./hlf_universidades.sh 
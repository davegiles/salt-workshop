wget -O - https://repo.saltstack.com/apt/ubuntu/ubuntu14/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/apt/ubuntu/ubuntu14/latest trusty main" >> /etc/apt/sources.list

sudo apt-get -y update

apt-get install -y salt-minion

sed -i '/#master: salt/c master: salt' /etc/salt/minion
echo "192.168.17.99 salt" >> /etc/hosts
# Eventually put completely custom configurations files to avoid dependency on format etc.

service salt-minion restart
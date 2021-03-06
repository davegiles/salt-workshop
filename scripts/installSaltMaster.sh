wget -O - https://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main" >> /etc/apt/sources.list.d/saltstack.list

sudo apt-get -yqq update
sudo apt-get -yqq upgrade

sudo apt-get install -yqq salt-master
sudo apt-get install -yqq salt-minion
sudo apt-get install -yqq salt-ssh

echo "192.168.17.100 salt" >> /etc/hosts
sudo cp /vagrant/conf/minion /etc/salt
sudo cp /vagrant/conf/master /etc/salt
sudo mkdir -p /srv/salt
sudo mkdir -p /srv/pillar

sudo service salt-master restart
sudo service salt-minion restart

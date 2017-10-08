wget -O - https://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/latest trusty main" >> /etc/apt/sources.list.d/saltstack.list

echo "192.168.17.100 salt" >> /etc/hosts
echo "127.0.0.1 0.sminion.learn.com" >> /etc/hosts
sudo hostnamectl set-hostname 0.sminion.learn.com

sudo apt-get -yqq update
sudo apt-get -yqq upgrade
sudo apt-get install -yqq --force-yes salt-minion
sudo cp /vagrant/conf/minion /etc/salt
sudo cp /vagrant/conf/_schedule.conf /etc/salt/minion.d

sudo service salt-minion restart

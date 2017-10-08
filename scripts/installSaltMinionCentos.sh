echo "192.168.17.100 salt" >> /etc/hosts
echo "127.0.0.1 1.sminion.learn.com" >> /etc/hosts
sudo hostnamectl set-hostname 1.sminion.learn.com

sudo yum -yq update
sudo yum -yq install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
sudo yum -yq clean expire-cache
sudo yum -yq install salt-minion

sudo cp /vagrant/conf/minion /etc/salt
sudo cp /vagrant/conf/_schedule.conf /etc/salt/minion.d

sudo systemctl restart salt-minion

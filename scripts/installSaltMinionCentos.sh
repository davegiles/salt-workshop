echo "192.168.17.100 salt" >> /etc/hosts
echo "127.0.0.1 1.sminion.learn.com" >> /etc/hosts
sudo hostnamectl set-hostname 1.sminion.learn.com

# Re-enable after 2017.7.3 is cut
# sudo yum -y -q update
# sudo yum -y -q install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
# sudo yum -y -q clean expire-cache
# sudo yum -y -q install salt-minion
sudo yum -y -q update
sudo rpm --import https://repo.saltstack.com/yum/redhat/7/x86_64/archive/2017.7.1/SALTSTACK-GPG-KEY.pub
cat <<'EOF' > /etc/yum.repos.d/saltstack.repo
[saltstack-repo]
name=SaltStack repo for RHEL/CentOS $releasever
baseurl=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/archive/2017.7.1
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/archive/2017.7.1/SALTSTACK-GPG-KEY.pub 
EOF
sudo yum -y -q clean expire-cache
sudo yum -y -q install salt-minion

sudo cp /vagrant/conf/minion /etc/salt
sudo cp /vagrant/conf/_schedule.conf /etc/salt/minion.d

sudo systemctl restart salt-minion
sudo systemctl enable salt-minion

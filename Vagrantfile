# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

MASTER_MEMORY = ENV.key?('MASTER_MEMORY') ? ENV['MASTER_MEMORY'] : 2048
MINION_MEMORY = ENV.key?('MINION_MEMORY') ? ENV['MINION_MEMORY'] : 512

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define 'salt_master' do |smaster|
    smaster.vm.box = 'ubuntu/trusty64'
    smaster.vm.network 'private_network', ip: '192.168.17.100'
    smaster.vm.hostname = 'smaster.learn.com'
    smaster.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', MASTER_MEMORY]
    end
    smaster.vm.provision 'shell', path: 'scripts/installSaltMaster.sh'
  end

  # Ubuntu Minion
  config.vm.define 'salt_minion_0' do |sminion|
    sminion.vm.box = 'ubuntu/trusty64'
    sminion.vm.network 'private_network', ip: '192.168.17.50'
    sminion.vm.hostname = '0.sminion.learn.com'
    sminion.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', MINION_MEMORY]
    end
    sminion.vm.provision 'shell' do |s|
        s.path = 'scripts/installSaltMinionUbuntu.sh'
    end
  end

  # CentOS Minion
  config.vm.define 'salt_minion_1' do |sminion|
    sminion.vm.box = 'centos/7'
    sminion.vm.network 'private_network', ip: '192.168.17.51'
    sminion.vm.hostname = '1.sminion.learn.com'
    sminion.vm.provider :virtualbox do |vb|
      vb.customize ['modifyvm', :id, '--memory', MINION_MEMORY]
    end
    sminion.vm.provision 'shell' do |s|
      s.path = 'scripts/installSaltMinionCentos.sh'
    end
  end
end

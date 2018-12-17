ssh_key_name = 'devvm'

Vagrant.configure("2") do |config|
  required_plugins = %w( vagrant-vbguest vagrant-disksize vagrant-hostmanager )
      _retry = false
      required_plugins.each do |plugin|
          unless Vagrant.has_plugin? plugin
              system "vagrant plugin install #{plugin}"
              _retry=true
          end
      end

      if (_retry)
          exec "vagrant " + ARGV.join(' ')
      end
  config.vm.box = "peru/ubuntu-18.04-desktop-amd64"
  config.vm.box_version = "20181210.01"
  config.vm.box_check_update = true
  config.disksize.size = "32GB"
  config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 2
        v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
        v.customize ["modifyvm", :id, "--usb", "on"]
        v.customize ["modifyvm", :id, "--vram", "128"]
        v.customize ["setextradata", :id, "CustomVideoMode1", "1680x1050x32"]
    end
  config.vm.provider "virtualbox"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "persistent-data", "/vagrant/persistent-data"
  config.vm.synced_folder "provisioning", "/vagrant/provisioning"

  if Vagrant::Util::Platform.windows? then
    config.vm.provision "file", source: "#{ENV['HOME']}\\.ssh\\#{ssh_key_name}", destination: "/tmp/#{ssh_key_name}", run: "always"
    config.vm.provision "file", source: "#{ENV['HOME']}\\.ssh\\#{ssh_key_name}.pub", destination: "/tmp/#{ssh_key_name}.pub", run: "always"
  else
    config.vm.provision "file", source: "#{ENV['HOME']}//.ssh//#{ssh_key_name}", destination: "/tmp/#{ssh_key_name}", run: "always"
    config.vm.provision "file", source: "#{ENV['HOME']}//.ssh//#{ssh_key_name}.pub", destination: "/tmp/#{ssh_key_name}.pub", run: "always"
  end


  config.vm.provision "shell", run: "always", inline: <<-SHELL
    set -o errexit -o pipefail -o nounset

    mv /tmp/#{ssh_key_name}* /home/vagrant/.ssh
    chmod 0400 /home/vagrant/.ssh/#{ssh_key_name}

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y

  	sudo add-apt-repository main
  	sudo add-apt-repository universe
  	sudo add-apt-repository restricted
  	sudo add-apt-repository multiverse
  	sudo apt update
  	sudo apt-get install -y software-properties-common
  	sudo apt-get update -y
  	sudo apt-get install -y python-setuptools python-dev build-essential
  	sudo apt-get install -y python-pip
  	sudo pip install ansible

    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y

    PYTHONUNBUFFERED=1 ANSIBLE_NOCOLOR=true /vagrant/provisioning/run.sh development_environment.yml


    apt-get autoremove -y
    apt-get clean
  SHELL
end

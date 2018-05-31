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
  config.vm.box_version = "20180530.01"
  config.vm.box_check_update = true
  config.disksize.size = "32GB"
  config.vm.provider "virtualbox" do |v|
        v.memory = 8128
        v.cpus = 2
        v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
        v.customize ["modifyvm", :id, "--usb", "on"]
        v.customize ["modifyvm", :id, "--vram", "128"]
        v.customize ["setextradata", :id, "CustomVideoMode1", "1680x1050x32"]
    end
  config.vm.provider "virtualbox"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "persistent-data", "/vagrant/persistent-data"
  
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    set -o errexit -o pipefail -o nounset

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
	sudo apt-get install virtualbox-guest-additions-iso
	sudo apt install build-essential dkms
	sudo apt-get install build-essential linux-headers-$(uname -r)
    apt-get autoremove -y
    apt-get clean
  SHELL
end
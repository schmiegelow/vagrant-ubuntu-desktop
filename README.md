# vagrant-ubuntu-desktop
A turn key Vagrant / Virtualbox environment to run Ubuntu 18.04 on Windows boxes comfortably.

This VM runs with Vagrant, ansible and Virtualbox. It uses Vagrant to spin up a Ubuntu box in Virtualbox and auto-provisions it with ansible roles. These roles contain the following packages:

- Docker and docker-compose
- Intellij
- Java SDK
- Chrome and Firefox browsers
- Chrome Driver for selenium
- NodeJS
- Python
- Fabric automation framework
- Terraform
- Ansible
- AWS CLI

Your files are stored in block devices that reside on the host, i.e. any update, or replacement of the VM will not affect your work. The block devices are in the persistent-data directory.

## Prerequisites

You need to install the following packages on your host:
- Vagrant: https://www.vagrantup.com/downloads.html (this will be installed automatically if you use the ```go``` command described in the next section)
- Virtualbox 5.1 (5.2 has a bug that prevents using block devices): https://www.virtualbox.org/wiki/Download_Old_Builds_5_1

## Usage

The project provides a convenient windows script that continuously updates the repo, associated vagrant boxes and plugins and runs the VM. Simply run ```go``` in your windows dos shell to use it. This assumes that you are not running in admin mode, but can switch to elevated privileges. You may need to reboot at first, if the script exits with an error message indicating a required reboot, restart you machine and run the script again to complete the installation.

Alternatively, you can run the following commands manually:

- ```git pull``` will update your repository
- ```vagrant box update``` will update your vagrant ubuntu box
- ```vagrant plugin update``` will update the installed plugins
- To start your VM, run ```vagrant up``` in the repo checkout directory. This will take a few minutes, as Vagrant will first download plugins it needs, spin up the box and then run the ansible scripts. The scripts will also create the block devices in which your code and settings reside. Each run will check the available disk space and expand it if necessary.
- To log in into your VM, use the user vagrant with vagrant as a password

Once ```go``` or ```vagrant up``` have completed, switch to the Virtualbox Windows UI; the VM will already be running. Double click on its entry to open the VM's UI.

To shutdown, run ```vagrant halt``` in the repo checkout directory.

_WARNING_: do not start your VM from Virtualbox directly. Always either use ```go.bat``` or ```vagrant up```. Failure to do so will leave you without windows shares and raw devices.

## Development set up

Your code should live in the dev directory in the vagrant user's home, which is /home/vagrant. This directory is linked to a persistent drive that stays even if the VM is recreated.

## Multi monitor set up

The VM runs with up to three monitors. To use them, enable your monitors in the Virtualbox VM menu on the top of the VM's window.

## Notes

- if your VM is still in text-only mode even after provisioning is completed, just run ```init 5``` to run in graphical target mode.

- Upon running vagrant, if VMware complains and exits with a VT-X error, you will need to disable Hyper V in Windows, by switching ```Control Panel -> Program and features -> Turn Windows features on and off -> Hyper V ``` off

- during provisioning, you might see an Ubuntu error message related to xfce-powermanager. This can be ignored.

- If clipboard copying is not enabled by default, select Devices -> Shared Clipboard -> Bidirectional in the Virtualbox menu bar

## Windows 7 Users

Please check that you have more than 8 GB RAM in your system. If not, you may have to temporarily reduce the amount of allocated RAM to 4 GB in the Vagrant file.

in addition, Windows 7 has the nasty habit of crashing virtual box due to services not running properly. If you see the following error:

```
Stderr: VBoxManage.exe: error: The virtual machine evise-development-environment_default
has terminated unexpectedly during startup with exit code 1 (0x1). (...)
VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component MachineWrap, interface IMachine
```

Specifically, if the VboxHardening.log file contains the following error:

```
0xc0000034 STATUS_OBJECT_NAME_NOT_FOUND (0 retries) Driver is probably stuck stopping/starting
```

You will need to run the following steps:

1. ```C:\Program Files\Oracle\VirtualBox\drivers\vboxdrv``` directory, right click on VBoxDrv.inf and select Install. You will be prompted for admin privileges
2. In an admin DOS box, run ```sc start vboxdrv```
3. run ```vagrant up``` again

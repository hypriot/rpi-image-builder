# -*- mode: ruby -*-
# vi: set ft=ruby :

# this Vagrantfile only works with VirtualBox so we set the default provider here
# so we can skip the --provider virtualbox option
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

# use half of the available memory
def get_memory_setting(host)
  divider = 2
  if host =~ /darwin/
    mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024 / divider
  elsif host =~ /linux/
    mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024 / divider
  else # Windows
    mem = `for /F "tokens=2 delims==" %i in ('wmic computersystem get TotalPhysicalMemory /value') do @echo %i`.to_i / 1024 / 1024 / divider
  end
  return mem
end

def get_cpu_setting(host)
  if host =~ /darwin/
    cpus = `sysctl -n hw.ncpu`.to_i
  elsif host =~ /linux/
    cpus = `nproc`.to_i
  else # Windows
    cpus = `for /F "tokens=2 delims==" %i in ('wmic cpu get NumberOfCores /value') do @echo %i`.to_i
  end
  return cpus
end

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.synced_folder ".", "/vagrant"
  config.vm.define "rpi-image-builder" do |config|
    config.vm.network "private_network", ip: "192.168.50.4"
    config.vm.hostname = "rpi-image-builder"
    config.ssh.forward_agent = true
    config.vm.provision "shell", path: "scripts/provision.sh", privileged: true
    config.vm.provider "virtualbox" do |vb|
       # find out on which host os we are running
       host = RbConfig::CONFIG['host_os']
       vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
       vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
       vb.customize ["modifyvm", :id, "--ioapic", "on"]
       vb.memory = get_memory_setting(host)
       vb.cpus = get_cpu_setting(host)
    end
  end
end

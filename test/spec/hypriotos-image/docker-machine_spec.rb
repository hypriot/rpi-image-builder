require 'spec_helper'

describe package('docker-machine') do
  it { should be_installed }
end

describe command('dpkg -l docker-machine') do
  its(:stdout) { should match /ii  docker-machine/ }
  its(:stdout) { should match /0.4.1-72/ }
  its(:exit_status) { should eq 0 }
end

describe file('/usr/local/bin/docker-machine') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe command('docker-machine --version') do
  its(:stdout) { should match /0.4.1/m }
  its(:exit_status) { should eq 0 }
end

describe command('docker-machine create --help') do
  its(:stdout) { should include("--hypriot-ip-address") }
  its(:stdout) { should include("--hypriot-ssh-key") }
  its(:stdout) { should include("--hypriot-ssh-port") }
  its(:stdout) { should include("--hypriot-ssh-user") }
  its(:exit_status) { should eq 0 }
end

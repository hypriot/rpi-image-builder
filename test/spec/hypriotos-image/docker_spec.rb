require 'spec_helper'

describe package('docker-hypriot') do
  it { should be_installed }
end

describe command('dpkg -l docker-hypriot') do
  its(:stdout) { should match /ii  docker-hypriot/ }
  its(:stdout) { should match /1.7.1-2/ }
  its(:exit_status) { should eq 0 }
end

describe file('/usr/bin/docker') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/usr/lib/docker/dockerinit') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/etc/init.d/docker') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/etc/default/docker') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  its(:content) { should match /--storage-driver=overlay/ }
end

describe file('/var/lib/docker') do
  it { should be_directory }
  it { should be_mode 700 }
  it { should be_owned_by 'root' }
end

describe file('/var/lib/docker/overlay') do
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

describe file('/var/lib/docker/repositories-overlay') do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by 'root' }
end

describe file('/etc/bash_completion.d/docker') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should be_file }
end

describe command('docker version') do
  its(:stdout) { should match /Client version: 1.7.1/ }
  its(:stdout) { should match /Server version: 1.7.1/ }
  its(:stdout) { should match /Client API version: 1.19/ }
  its(:stdout) { should match /Server API version: 1.19/ }
  its(:exit_status) { should eq 0 }
end

describe command('docker info') do
  its(:stdout) { should match /Storage Driver: overlay/ }
  its(:exit_status) { should eq 0 }
end

describe interface('eth0') do
  it { should exist }
end

describe interface('docker0') do
  it { should exist }
end

describe service('docker') do
  it { should be_enabled }
  it { should be_running }
end

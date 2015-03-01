require 'spec_helper'

describe package('docker-hypriot') do
  it { should be_installed }
end

describe command('dpkg -l docker-hypriot') do
  its(:stdout) { should match /ii  docker-hypriot/ }
  its(:stdout) { should match /1.5.0-7/ }
  its(:exit_status) { should eq 0 }
end

describe file('/etc/default/docker') do
  its(:content) { should match /--storage-driver=overlay/ }
end

describe command('docker version') do
  its(:stdout) { should match /Client version: 1.5.0/ }
  its(:stdout) { should match /Server version: 1.5.0/ }
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

describe file('/etc/bash_completion.d/docker') do
  it { should be_file }
end

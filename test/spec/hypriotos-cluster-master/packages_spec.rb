require 'spec_helper'

describe package('vlan') do
  it { should be_installed }
end

describe package('avahi-utils') do
  it { should be_installed }
end

describe package('dnsmasq') do
  it { should be_installed }
end

describe package('hypriot-cluster-lab') do
  it { should be_installed }
end

describe command("dpkg -l hypriot-cluster-lab") do
  its(:stdout) { should contain(" 0.1.1-") }
end

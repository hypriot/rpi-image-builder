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

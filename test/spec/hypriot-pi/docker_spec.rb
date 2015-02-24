require 'spec_helper'

describe package('docker-hypriot') do
  it { should be_installed }
end

describe file('/etc/default/docker') do
  its(:content) { should match /--storage-driver=overlay/ }
end
require 'spec_helper'

describe docker_image('hypriot/rpi-swarm:latest') do
  it { should exist }
  its(['Architecture']) { should eq 'arm' }
end

describe file('/var/hypriot/swarm.tar.gz') do
  it { should_not be_file }
end

describe command('docker run --rm -t hypriot/rpi-swarm --version') do
  its(:stdout) { should match /swarm version 1.0.0 \(HEAD\)/ }
  its(:exit_status) { should eq 0 }
end

require 'spec_helper'

describe docker_image('hypriot/rpi-swarm:latest') do
  it { should exist }
  its(['Architecture']) { should eq 'arm' }
end

describe docker_image('hypriot/rpi-consul:0.6.0') do
  it { should exist }
  its(['Architecture']) { should eq 'arm' }
end

describe docker_container('bin_swarmmanage_1') do
  it { should be_running }
end

describe docker_container('bin_consul_1') do
  it { should be_running }
end

describe docker_container('bin_swarm_1') do
  it { should be_running }
end

require 'spec_helper'

describe docker_container('bin_swarmmanage_1') do
  it { should be_running }
end

describe docker_container('bin_consul_1') do
  it { should be_running }
end

describe docker_container('bin_swarm_1') do
  it { should be_running }
end

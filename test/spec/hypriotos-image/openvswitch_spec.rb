Specinfra::Runner.run_command('modprobe openvswitch vxlan gre')

describe kernel_module('openvswitch') do
  it { should be_loaded }
end

describe kernel_module('vxlan') do
  it { should be_loaded }
end

describe kernel_module('gre') do
  it { should be_loaded }
end

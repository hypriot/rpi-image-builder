describe command('uname -r') do
  its(:stdout) { should match /3.18.7(-v7)?+/ }
  its(:exit_status) { should eq 0 }
end

describe kernel_module('overlay') do
  it { should be_loaded }
end

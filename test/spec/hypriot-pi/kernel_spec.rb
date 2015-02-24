describe command('uname -r') do
  its(:stdout) { should eq "3.18.7-v7+\n" }
  its(:exit_status) { should eq 0 }
end

describe kernel_module('overlay') do
  it { should be_loaded }
end

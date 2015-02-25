describe command('uname -r') do
  its(:stdout) { should match /3.18.7(-v7)?+/ }
  its(:exit_status) { should eq 0 }
end

describe kernel_module('overlay') do
  it { should be_loaded }
end

describe file('/boot/cmdline.txt') do
  it { should be_file }
  its(:content) { should match /console=tty1/ }
  its(:content) { should match /rootfstype=ext4 cgroup-enable=memory/ }
end

describe command('uname -r') do
  its(:stdout) { should match /3.18.8(-v7)?+/ }
  its(:exit_status) { should eq 0 }
end

describe file('/lib/modules/3.18.7+/build') do
  it { should_not be_file }
  it { should_not be_symlink }
end

describe file('/lib/modules/3.18.7-v7+/build') do
  it { should_not be_file }
  it { should_not be_symlink }
end

describe file('/lib/modules/3.18.8+/build') do
  it { should_not be_file }
  it { should_not be_symlink }
end

describe file('/lib/modules/3.18.8-v7+/build') do
  it { should_not be_file }
  it { should_not be_symlink }
end

describe kernel_module('overlay') do
  it { should be_loaded }
end

describe file('/boot/cmdline.txt') do
  it { should be_file }
  its(:content) { should match /console=tty1/ }
  its(:content) { should match /rootfstype=ext4/ }
  its(:content) { should match /cgroup-enable=memory/ }
  its(:content) { should match /swapaccount=1/ }
end

describe command('uname -r') do
  its(:stdout) { should match /3.18.8-hypriotos(-v7)?+/ }
  its(:exit_status) { should eq 0 }
end

describe file('/lib/modules/3.18.8+') do
  it { should_not be_directory }
end

describe file('/lib/modules/3.18.8-v7+') do
  it { should_not be_directory }
end

describe file('/lib/modules/3.18.7+') do
  it { should_not be_directory }
end

describe file('/lib/modules/3.18.7-v7+') do
  it { should_not be_directory }
end

describe kernel_module('overlay') do
  it { should be_loaded }
end

describe file('/boot/cmdline.txt') do
  it { should be_file }
  its(:content) { should match /console=tty1/ }
  its(:content) { should match /rootfstype=ext4 cgroup-enable=memory/ }
end

# with installed kernel headers
describe file('/lib/modules/3.18.8-hypriotos+/build') do
  it { should be_symlink }
  it { should be_linked_to '/usr/src/linux-headers-3.18.8-hypriotos+' }
end

describe file('/lib/modules/3.18.8-hypriotos-v7+/build') do
  it { should be_symlink }
  it { should be_linked_to '/usr/src/linux-headers-3.18.8-hypriotos-v7+' }
end

describe file('/usr/src/linux-headers-3.18.8-hypriotos-v7+') do
  it { should be_directory }
end

describe file('/usr/src/linux-headers-3.18.8-hypriotos+') do
  it { should be_directory }
end

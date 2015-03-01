describe command('ps -ax') do
  its(:stdout) { should match /getty -L ttyAMA0 115200 vt100/ }
end

describe file('/boot/cmdline.txt') do
  its(:content) { should match /\+dwc_otg.lpm_enable=0/ }
  its(:content) { should match /console=ttyAMA0,115200/ }
  its(:content) { should match /kgdboc=ttyAMA0,115200/ }
end

describe file('/usr/bin/rpi-serial-console') do
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
end

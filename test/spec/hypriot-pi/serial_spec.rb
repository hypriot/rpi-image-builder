describe command('ps -ef') do
  its(:stdout) { should match /getty -L ttyAMA0 115200 vt100/ }
end

describe file('/boot/cmdline.txt') do
  its(:content) { should match /console=ttyAMA0,115200 kgdboc=ttyAMA0,115200/ }
end

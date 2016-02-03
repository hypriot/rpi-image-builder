require 'spec_helper'

describe docker_image('hypriot/rpi-consul:0.6.0') do
  it { should exist }
  its(['Architecture']) { should eq 'arm' }
end

describe command('docker run -t --rm hypriot/rpi-consul:0.6.0 --version') do
  its(:stdout) { should match /0.6.0/ }
  its(:stderr) { should match /^$/ }
  its(:exit_status) { should eq 0 }
end

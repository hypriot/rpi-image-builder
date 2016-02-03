require 'spec_helper'

describe command('docker images hypriot/rpi-consul') do
  its(:stdout) { should match /hypriot\/rpi-consul .*0.6.0 .*15447d873499 / }
  its(:exit_status) { should eq 0 }
end

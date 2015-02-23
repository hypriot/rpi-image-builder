require 'spec_helper'

describe package('docker-hypriot') do
  it { should be_installed }
end


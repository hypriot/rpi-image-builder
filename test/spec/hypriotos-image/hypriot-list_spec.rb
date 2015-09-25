require 'spec_helper'

describe file('/etc/apt/sources.list.d/hypriot.list') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should contain 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' }
end

require 'spec_helper'

# /proc/device-tree is only present if device-tree works
describe file('/proc/device-tree') do
  it { should be_symlink }
  it { should be_linked_to '/sys/firmware/devicetree/base' }
  it { should be_mode 777 }
  it { should be_owned_by 'root' }
end

describe file('/proc/device-tree/cpus') do
  it { should be_directory}
end


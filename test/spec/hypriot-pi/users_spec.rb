describe user('root') do
  it { should exist }
  it { should have_home_directory '/root' }
  it { should have_login_shell '/bin/bash' }
end

describe group('docker') do
  it { should exist }
end

describe user('pi') do
  it { should exist }
  it { should have_home_directory '/home/pi' }
  it { should have_login_shell '/bin/bash' }
  it { should belong_to_group 'docker' }
end

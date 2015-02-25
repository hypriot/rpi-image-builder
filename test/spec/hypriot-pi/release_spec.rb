describe file('/etc/hypriot_release') do
  it { should be_file }
  its(:content) { should match /profile: hypriot/ }
  its(:content) { should match /build: \d+\-\d+/ }
end

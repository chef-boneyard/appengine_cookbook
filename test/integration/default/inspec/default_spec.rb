describe file('/tmp/hello_world/app.yaml') do
  it { should exist }
end

describe package('wget') do
  it { should be_installed }
end

describe command('wget -qO- http://wrong.appengine.com') do
  its('stdout') { should eq 'Hello, World! Now' }
end

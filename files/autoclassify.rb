#!/opt/puppet/bin/ruby

require 'puppet'
require 'puppet/ssl/certificate'

def get_clientcert_name(path)
  File.basename(path, 'pem')
end

def get_and_write(clientcert)
  puts clientcert
  if File.exists?(clientcert)
    cert = Puppet::SSL::Certificate.new(get_clientcert_name(clientcert))
    cert_file = cert.read(clientcert)
    extensions = cert_file.extensions
    extensions.each do |line|
      if line.oid == '1.3.6.1.4.1.34380.1.2.2'
        classifier_data = line.value
        system("/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production node:add[#{clientcert},'default',#{classifier_data},skip]")
      end
    end
  else
    puts "Oops"
  end
end

if File.file?(ARGV[0])
  get_and_write(ARGV[0])
elsif File.directory?(ARGV[0])
  Dir.ARGV[0].each do |single_file|
    get_and_write(single_file)
  end
end

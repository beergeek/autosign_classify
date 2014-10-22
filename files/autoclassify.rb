#!/opt/puppet/bin/ruby

require 'puppet'
require 'puppet/ssl/certificate'
require 'syslog'

# lets setup some logging
Syslog.open("autoclassifier", Syslog::LOG_PID, Syslog::LOG_SYSLOG)

def get_and_write(clientcert)
  # is it really a file?
  if File.exists?(clientcert)
    begin
      # This will fail if it is not a certificate, hence the rescue below
      base_cert = File.basename(clientcert, '.pem')
      cert = Puppet::SSL::Certificate.new(base_cert)
      cert_file = cert.read(clientcert)
      cert_file.extensions.each do |line|
        # Does it have the extension we need?
        if line.oid == '1.3.6.1.4.1.34380.1.2.2'
          classifier_data = line.value
          # Call the Rake API to classify.
          # This will not work if the node already exists
          Syslog.log(Syslog::LOG_INFO, "Attempting to classify #{base_cert}")
          system("/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production node:add[#{base_cert},'default',#{classifier_data},skip]")
        end
      end
    rescue Exception => e
      Syslog.log(Syslog::LOG_WARNING, "We had an error with the autoclassifier: #{e}")
    end
  end
end

if File.file?(ARGV[0])
  get_and_write(ARGV[0])
elsif File.directory?(ARGV[0])
  Dir.foreach(ARGV[0]) do |single_file|
    next if single_file == '.' or single_file == '..'
    get_and_write(File.join(ARGV[0],single_file))
  end
end

def puppet4_available?
  success = []
  success << Kafo::Helpers.execute('yum info puppet-agent')
  success << Kafo::Helpers.execute('yum info puppetserver')
  success.include?(false)
end

def stop_services
  Kafo::Helpers.execute('katello-service stop')
end

def upgrade_puppet_package
  Kafo::Helpers.execute('yum remove -y puppet-server')
  Kafo::Helpers.execute('yum install -y puppetserver')
  Kafo::Helpers.execute('yum install -y puppet-agent')
end

def copy_data
  success = []
  success << Kafo::Helpers.execute('cp -rfp /etc/puppet/environments/* /etc/puppetlabs/code/environments') if File.directory?('/etc/puppet/environments')
  success << Kafo::Helpers.execute('mv /var/lib/puppet/ssl /etc/puppetlabs/puppet') if File.directory?('/var/lib/puppet/ssl')
  success << Kafo::Helpers.execute('mv /var/lib/puppet/foreman_cache_data /opt/puppetlabs/puppet/cache/') if File.directory?('/var/lib/puppet/foreman_cache_data')
  success.include?(false)
end

def upgrade_step(step)
  noop = app_value(:noop) ? ' (noop)' : ''

  Kafo::Helpers.log_and_say :info, "Upgrade Step: #{step}#{noop}..."
  unless app_value(:noop)
    status = send(step)
    fail_and_exit "Upgrade step #{step} failed. Check logs for more information." unless status
  end
end

def fail_and_exit(message)
  Kafo::Helpers.log_and_say :error, message
  kafo.class.exit 1
end

def reset_value(param)
  param.value = param.default
end

if app_value(:upgrade_puppet)
  Kafo::Helpers.log_and_say :info, 'Upgrading puppet...'
  fail_and_exit 'Unable to find Puppet 4 packages, is the repository enabled?' unless puppet4_available?

  # set installer params for upgrade
  param('capsule', 'puppet_server_implementation').value = 'puppetserver'

  reset_value(param('foreman', 'puppet_home'))
  reset_value(param('foreman', 'puppet_ssldir'))
  reset_value(param('foreman_proxy', 'puppet_ssl_ca'))
  reset_value(param('foreman_proxy', 'puppet_ssl_cert'))
  reset_value(param('foreman_proxy', 'puppet_ssl_key'))
  reset_value(param('foreman_proxy', 'puppetdir'))
  reset_value(param('foreman_proxy', 'ssldir'))

  upgrade_step :stop_services
  upgrade_step :upgrade_puppet_package
  upgrade_step :copy_data

  Kafo::Helpers.log_and_say :info, "Puppet 3 to 4 upgrade initialization complete, continuing with installation"
end

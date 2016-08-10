def stop_services                                                                                                                                                                                                                                     [0/1892]
  Kafo::Helpers.execute('katello-service stop')
end

def upgrade_puppet_pkg
  Kafo::Helpers.execute('yum remove -y puppet-server')
  Kafo::Helpers.execute('yum install -y puppetserver')
  Kafo::Helpers.execute('yum install -y puppet-agent')
end

def populate_p4_environments
  Kafo::Helpers.execute('cp -rfp /etc/puppet/environments/* /etc/puppetlabs/code/environments')
end

def copy_ssl_certs
  Kafo::Helpers.execute('mv /var/lib/puppet/ssl /etc/puppetlabs/puppet')
  Kafo::Helpers.execute('mv /var/lib/puppet/foreman_cache_data /opt/puppetlabs/puppet/cache/')
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
  # set installer params for upgrade
  param('capsule', 'puppet_server_implementation').value = 'puppetserver'

  reset_value(param('foreman', 'puppet_home'))
  reset_value(param('foreman', 'puppet_ssldir'))
  reset_value(param('foreman_proxy', 'puppet_ssl_ca'))
  reset_value(param('foreman_proxy', 'puppet_ssl_cert'))
  reset_value(param('foreman_proxy', 'puppet_ssl_key'))
  reset_value(param('foreman_proxy', 'puppetdir'))
  reset_value(param('foreman_proxy', 'ssldir'))

  Kafo::Helpers.log_and_say :info, "Puppet 3 to 4 upgrade initialization complete, continuing with installation"
end


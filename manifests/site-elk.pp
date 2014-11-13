node puppet {
  class {'rsyslog':
    ssl => true,
  }

  class { '::rsyslog::client':
    log_local  => 'true',
    server     => 'rsyslog',
    ssl_ca     => "/var/lib/puppet/ssl/certs/ca.pem",
  }
}

node rsyslog {
  class {'rsyslog':
    ssl => true,
  }

  class { '::rsyslog::server':
    server_dir => '/srv/log/',
    ssl_ca     => "/var/lib/puppet/ssl/certs/ca.pem",
    ssl_cert   => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    ssl_key    => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
  }

  $config_hash = {
    'LS_USER' => 'root',
  }
  class { 'logstash':
    package_url   => 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm',
    java_install  => true,
    init_defaults => $config_hash
  }

  logstash::configfile { 'input_rsyslog':
    content => template('logstash/input_rsyslog.erb'),
    order   => 10
  }

  logstash::configfile { 'filter_rsyslog':
    content => template('logstash/filter_rsyslog.erb'),
    order   => 20
  }

  logstash::configfile { 'output_es':
    content => template('logstash/output_es.erb'),
    order    => 30
  }
}

node client {
  class {'rsyslog':
    ssl => true,
  }

  class { '::rsyslog::client':
    log_local  => 'true',
    server     => 'rsyslog',
    ssl_ca     => "/var/lib/puppet/ssl/certs/ca.pem",
  }
}

node elk {
  class {'rsyslog':
    ssl => true,
  }

  class { '::rsyslog::client':
    log_local  => 'true',
    server     => 'rsyslog',
    ssl_ca     => "/var/lib/puppet/ssl/certs/ca.pem",
  }

  class { 'elasticsearch':
    java_install => true,
    package_url  => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.0.noarch.rpm',
  }

  elasticsearch::instance { 'elasticsearch':
    config       => { 'cluster.name' => 'puppetconf' },
  }

  elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
    module_dir  => 'kopf',
    instances   => ['elasticsearch']
  }

  elasticsearch::plugin{'mobz/elasticsearch-head':
    module_dir  => 'head',
    instances   => ['elasticsearch']
  }

  class { 'kibana3':
    config_es_server   => 'localhost',
    require            => Class['Elasticsearch']
  }

}

require 'spec_helper'
describe 'autosign_classify' do
  before do
    Puppet[:confdir] = '/etc/puppetlabs/puppet'
  end

  context 'with defaults for all parameters' do
    let(:facts) {
      {
        :osfamily => 'RedHat',
      }
    }
    it { should contain_class('autosign_classify') }

    it {
      should contain_package('rsync').with(
        'ensure'  => 'present',
      )
    }

  end

  context 'as primary server' do
    let(:facts) {
      {
        :osfamily => 'RedHat',
      }
    }
    let(:params) {
      {
        :primary  => true,
      }
    }
    it { should contain_class('autosign_classify') }

    it {
      should contain_package('rsync').with(
        'ensure'  => 'present',
      )
    }

    it {
      should contain_file('autosigner').with(
        'ensure'  => 'file',
        'path'    => '/opt/puppet/bin/autosign.rb',
        'owner'   => 'puppet',
        'group'   => 'puppet',
        'mode'    => '0755',
      )
    }

    it {
      should contain_ini_setting('autosign').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppet/puppet.conf',
        'section' => 'master',
        'setting' => 'autosign',
        'value'   => '/opt/puppet/bin/autosign.rb',
      ).that_requires('File[autosigner]')
    }

    it {
      should contain_package('incron').with(
        'ensure'  => 'present',
      )
    }

    it {
      should contain_file('autoclassifier').with(
        'ensure'  => 'file',
        'owner'   => 'puppet-dashboard',
        'group'   => 'root',
        'mode'    => '0744',
        'source'  => 'puppet:///modules/autosign_classify/autoclassify.rb',
      )
    }

    it {
      should contain_file('/etc/incron.d/autoclassify').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0744',
      ).with_content(/\/opt\/puppet\/share\/puppet-dashboard\/autoclassify.rb/)
      .that_requires('Package[incron]')
      .that_requires('File[autoclassifier]')
    }

    it {
      should contain_service('incrond').with(
        'ensure'  => 'running',
      ).that_subscribes_to('File[/etc/incron.d/autoclassify]')
    }
    it {
      should contain_file('/etc/incron.d/sync_certs').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0744',
      )
    }
  end
end

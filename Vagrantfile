# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure(2) do |config|

    File.write('IP', "10.10.10.#{rand(10..250)}") if not File.exists?('IP')

    config.vm.box = "wplib/wplib"
    config.vm.hostname = "wabe.dev"
    config.hostsupdater.aliases = [
        "adminer.wplib.box",
        "mailhog.wplib.box"
    ]

    config.vm.network 'private_network', ip: IO.read('IP').strip

    config.vm.synced_folder "www", "/var/www"

    config.ssh.forward_agent = true
    config.ssh.insert_key = false

    $provision = <<PROVISION
if [ -f "/vagrant/scripts/provision.sh" ]; then
    bash /vagrant/scripts/provision.sh --force
else
    rm -rf /tmp/box-scripts  2>/dev/null
    git clone https://github.com/wplib/box-scripts.git /tmp/box-scripts  2>/dev/null
    bash /tmp/box-scripts/provision.sh
fi
PROVISION

    config.vm.provision "shell", inline: $provision

    config.trigger.before :halt do
        run_remote "box backup-db"
    end

end


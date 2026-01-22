Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "manager01" do |manager|
    manager.vm.hostname = "manager01"
    manager.vm.network "private_network", ip: "192.168.56.10"  

    manager.vm.network "forwarded_port", guest: 8081, host: 8081, auto_correct: true
    manager.vm.network "forwarded_port", guest: 8087, host: 8087, auto_correct: true

    manager.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end

    manager.vm.provision "shell", path: "scripts/docker.sh"
    manager.vm.provision "shell", path: "scripts/docker-swarm-init.sh"


  end

  config.vm.define "worker01" do |worker1|
    worker1.vm.hostname = "worker1"
    worker1.vm.network "private_network", ip: "192.168.56.11"

    worker1.vm.provision "shell", path: "scripts/docker.sh"
    worker1.vm.provision "shell", path: "scripts/docker-swarm-init.sh"


  end

  config.vm.define "worker02" do |worker2|
    worker2.vm.hostname = "worker2"
    worker2.vm.network "private_network", ip: "192.168.56.12"

    worker2.vm.provision "shell", path: "scripts/docker.sh"
    worker2.vm.provision "shell", path: "scripts/docker-swarm-init.sh"

    
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 2
  end
end
# Vagrant Utility for automated k8s cluster setup

Vagrantfile and ansible playbooks to create single-master k8s cluster with CentOS as base image.
IPs, k8s version and proxy settings are configurable and to be modified in config/config.yml

 
## Prerequisites:
- CentOS box
- Vagrant should be installed on your machine. Installation binaries can be found [here](https://www.vagrantup.com/downloads.html)
- Oracle VirtualBox can be used as a Vagrant provider or make use of similar providers as described in [Vagrant’s official documentation](https://www.vagrantup.com/docs/providers/)
- Ansible should be installed in your machine. Refer to the [Ansible installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) for platform specific installation. 
- Helpful links for vagrant and VirtualBox setup:
  - [VirtualBox 6.0 installation](https://www.itzgeek.com/how-tos/linux/centos-how-tos/install-virtualbox-4-3-on-centos-7-rhel-7.html)
  - [Vagrant installation](https://phoenixnap.com/kb/how-to-install-vagrant-on-centos-7)
- Disable strick host checking for ansible, set below env variable:
    - $ export ANSIBLE_HOST_KEY_CHECKING=False
- Install proxy plugin for vagrant
    - $ vagrant plugin install vagrant-proxyconf
- Clone the repository
  - $ cd ~
  - $ git clone -b k8s_cluster_vagrant https://github.com/saranke/hpe3par_test_automation.git
  - $ cd hpe3par_test_automation
  - Modify config/config.yml and provide master and worker nodes IPs, k8s version and http/https/no-proxy settings.
  - Modify hosts file as well if working on CSI driver.

## Steps to create cluster:
- After setting up prerequisites, execute below command to create single-master k8s cluster.
  - $ cd hpe3par_test_automation
  - $ vagrant up [ vagrant up --debug to enable debug logs]

## Steps for driver installation:
  ### Deploy CSI plugin
  - Install latest helm chart.
    - helm repo add hpe https://hpe-storage.github.io/co-deployments
    - helm repo update
    - helm install hpe-csi hpe/hpe-csi-driver --namespace hpe-storage
  - Install with tgz
    - helm install hpe-csi <tgz_file> -n <namespace> -f values.yml
  
    
  ### Deploy flex volume plugin 
  - Clone ansible installer 
    - $ git clone https://github.com/hpe-storage/python-hpedockerplugin.git
    - $ cd python-hpedockerplugin-master/ansible_3par_docker_plugin
    - Modify inventory (hosts) and properties/plugin_configuration_properties.yml
      > NOTE: Please follow [steps](https://github.com/hpe-storage/python-  hpedockerplugin/tree/master/ansible_3par_docker_plugin)
  - Execute below script to modify eth in installer files to avoid etcd service issue in cluster 
     - $ sh flex_etcd_sol.sh <path_to_ansible_installer_root>
     - eg $ sh flex_etcd_sol.sh hpedockerplugin/ansible_3par_docker_plugin
  - Execute install_libs.yml to setup ssh connectivity between k8s cluster nodes for execution of automation test. Modify hosts accordingly.
    - $ ansible-playbook -i hosts install_libs.yml
      > NOTE: hosts is needed as node-ips are fetched from the same.

  ### Steps for Automation Test Execution:
  - ssh to master node disabling StrickHostKeyChecking
    - $ ssh -o StrictHostKeyChecking=no master_node_ip
  - Clone test automation 
    - For CSI driver
      - $ git clone -b kubernetes_automation https://github.com/saranke/hpe3par_test_automation.git
    - For flex volume driver
      - $ git clone -b k8s_auto https://github.com/saranke/hpe3par_test_automation.git
  - Execute test
    - $ cd hpe3par_test_automation
    - $ pytest <module names> --backend <ARRAY_IP> --access_protocol <iscsi/fc> --platform <k8s/os> (k8s is default)

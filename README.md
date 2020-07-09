# Vagrant Utility for automated k8s cluster setup

Vagrantfile and ansible playbooks to create single-master k8s cluster with CentOS as base image.
IPs, k8s version and proxy settings are configurable and to be modified in config/config.yml

 
## Prerequisites:
- CentOS box
- Vagrant should be installed on your machine. Installation binaries can be found [here](https://www.vagrantup.com/downloads.html)
- Oracle VirtualBox can be used as a Vagrant provider or make use of similar providers as described in [Vagrant’s official documentation](https://www.vagrantup.com/docs/providers/)
- Ansible should be installed in your machine. Refer to the [Ansible installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) for platform specific installation. 
- Some helpful links:
  - [VirtualBox 6.0 installation](https://www.itzgeek.com/how-tos/linux/centos-how-tos/install-virtualbox-4-3-on-centos-7-rhel-7.html)
  - [Vagrant installation](https://phoenixnap.com/kb/how-to-install-vagrant-on-centos-7)
- Disable strick host checking for ansible, set below env variable:
    - $ export ANSIBLE_HOST_KEY_CHECKING=False
- Install proxy plugin for vagrant
    - $ vagrant plugin install vagrant-proxyconf
- Clone the python-hpedockerplugin repository
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

  ### Deploy CSI & CSP driver:
  - Make sure config/config.yaml and hosts are updated with correct VM IPs and proxy urls.
  - Execute below script that copies required files to master node.
    - $ ansible-playbook -i hosts copy_files_to_master.yml
  - Connect to master node via ssh
    - $ ssh -o StrictHostKeyChecking=no master_node_ip
  - Deploy CSI driver
    - $ kubectl create -f https://raw.github.hpe.com/Ecosystem-Integration/hpe_3par_primera_csp/master/build/hpe-csi-k8s-1.16.yaml
  - Deploy CSP driver
    - $ kubectl create -f https://github.hpe.com/Ecosystem-Integration/hpe_3par_primera_csp/blob/master/build/hpe3parprimera.yml (please verify image name)
  - Wait till all pods come to Running state
    - $ kubectl get pods --all-namespaces -o wide
  - Now apply workaround to re-route CSP service 
    - $ ansible-playbook -i hosts csi_fix.yaml 
    > Note: hosts, csi_fix.yaml and config.yaml are copied from blade via execution of copy_files_to_master.yml 
  - Now delete the csi pod
    - $ kubectl delete pods --selector  app=hpe-csi-controller -n kube-system
  - Verify again if all pods in running state
    - $ kubectl get pods --all-namespaces -o wide
    
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
      - $ git clone -b csi_k8s_test_automation https://github.com/saranke/hpe3par_test_automation.git
    - For flex volume driver
      - $ git clone -b k8s_auto https://github.com/saranke/hpe3par_test_automation.git
  - Execute test
    - $ cd hpe3par_test_automation
    - $ pytest -s

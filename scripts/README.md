## Kubeadm Cluster Setup Scripts on Ubuntu
Login into master VM and run
~~~shell
./common.sh master
~~~

Then on master node install kubernetes components:
~~~shell
./components.sh
~~~

Then login into other VMs und run
~~~shell
./common.sh worker IP_MASTER_VM TOKEN
~~~


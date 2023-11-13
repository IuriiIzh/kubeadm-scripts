## Kubeadm Cluster Setup Scripts on Ubuntu
Login into master VM and run
~~~shell
./common.sh master
~~~

Then on master node install kubernetes components:
~~~shell
./components.sh
~~~

If you forgot you join-token you can use this command on master VM:
~~~shell
kubeadm token create --print-join-command
~~~
Then login into other VMs und run
~~~shell
./common.sh worker IP_MASTER_VM:PORT TOKEN HASH
~~~


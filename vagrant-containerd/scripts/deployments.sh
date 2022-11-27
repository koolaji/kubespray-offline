if [ $1 = 'master' ]
then
	set -x
        export DEBIAN_FRONTEND=noninteractive
        echo 'nameserver 8.8.8.8' > /etc/resolv.conf
        ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime
	apt update &&   apt install -y ntp sshpass
        ntpq -p
	cp /vagrant/configs/hosts /etc/hosts
	cp -r /tmp/outputs /root && rm -r /tmp/outputs
	ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
	cd /root/outputs
	bash setup-container.sh
	bash start-nginx.sh
	bash setup-offline.sh
	bash setup-py.sh
	bash start-registry.sh
	bash load-push-all-images.sh 
	bash extract-kubespray.sh
	python3 -m venv ~/.venv/default
	source ~/.venv/default/bin/activate
	cd kubespray-2.20.0/
	pip install -U pip
	pip install -r requirements.txt
	cp -r  ../playbook/* .
	sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no root@node01
	sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no root@node02
	sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no root@node03
	sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no root@node04
	cp -rfp inventory/sample inventory/mycluster
	cp  /vagrant/configs/offline.yml  inventory/mycluster/group_vars/all/offline.yml
	cp  /vagrant/configs/inventory.ini     inventory/mycluster
	ansible-playbook -i inventory/mycluster/inventory.ini offline-repo.yml
	ansible-playbook -i inventory/mycluster/inventory.ini  --become --become-user=root cluster.yml
else
        export DEBIAN_FRONTEND=noninteractive
        echo 'nameserver 8.8.8.8' > /etc/resolv.conf
	cp /vagrant//configs/hosts /etc/hosts
        ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime
	apt update &&   apt install -y ntp sshpass
        ntpq -p
	echo -e  "vagrant\nvagrant" | passwd
	cp /vagrant/configs/sshd_config /etc/ssh/sshd_config
	systemctl restart ssh
fi


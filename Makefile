.PHONY: clean destroy master-ip kubectl-conf

# create the k8s cluster
instance: 
	vagrant up
	rm -rf ./tmp

# destroy the k8s cluster
destroy:
	vagrant destroy --force

# configure kubectl conf env var
kubectl-conf:
	echo "Execute the following:" 
	export KUBECONFIG=${PWD}/.kube/config

cluster-info: kubectl-conf
	kubectl cluster-info

vm-status:
	vagrant status

master-ip:
	vagrant ssh -c "hostname -I | cut -d' ' -f 2"

# clean the workspace
clean: destroy
	rm -rf ./tmp/ ./.kube/

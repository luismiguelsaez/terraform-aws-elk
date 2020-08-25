### Download terraform
```
$ curl -sL https://releases.hashicorp.com/terraform/0.12.4/terraform_0.12.4_linux_amd64.zip -O bin
$ unzip bin/terraform_0.12.4_linux_amd64.zip -d bin
$ export PATH=${PWD}/bin:${PATH}
```

### Clone roles
```
$ ansible-galaxy install --force --ignore-errors -r requirements.yml
```

### OST commands
- Get available image list
    ```
    $ openstack --insecure image list
    ```

### Previous steps

* Populate ```vault/secrets.yml``` file with needed user/password info

    * Decrypt file

        ```
        ansible-vault decrypt vault/secrets.yml
        ```

    * Edit information

    * Encrypt file

        ```
        ansible-vault encrypt vault/secrets.yml
        ```

### Execute deployment playbooks
```
$ ansible-playbook playbooks/00-create.yml

$ ansible-playbook playbooks/01-python-setup.yml playbooks/04-elk-gen-certificates.yml playbooks/05-elk-stack-kibana.yml playbooks/06-elk-stack-elasticsearch.yml playbooks/07-elk-stack-logstash.yml playbooks/08-elk-stack-beats.yml --ask-vault-pass
```

### SSH connection
```
$ ssh -C -F ./ssh/bastion.config ec2-user@ip-10-5-4-84.eu-west-1.compute.internal
```
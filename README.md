## Implementation

 ## Installation of Ubuntu

At the beginning of the project implementation, I needed to set up a controller to develop the scripts with Terraform and Ansible. For this purpose, I downloaded the Ubuntu 22.04.4 LTS ISO (LTS stands for Long-Term Support, indicating that a particular version is supported and updated by a company or community for a specified period). I created a new virtual machine (master.test.lab) in vCenter and configured this VM with 2 CPUs, 4 GB of RAM, and a 60 GB hard drive. During the Ubuntu installation, I used the default settings and set up a graphical user interface. I assigned a password to the user "goerkem," and the controller is accessible via the IP address "192.168.44.85."

###  Installation and Configuration of Ansible

Before starting the Ansible installation, my Ubuntu server should be updated. To update the server, we execute the following command:

```bash
sudo apt update
```

Then, I executed the following commands to install Ansible:

```bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt install ansible
ansible --version
```

Python: On Ubuntu systems, Python is usually already installed. If not, we can install it with:

```bash
sudo apt install python
```

### Installation and Configuration of Terraform

First, the HashiCorp GPG Key (a digital signature used to verify HashiCorp software products) must be installed on the controller. This command was executed:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

After adding the key, the HashiCorp repository should be added to our system:

```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

To install Terraform, execute this command:

```bash
sudo apt update
sudo apt install terraform
```

Now Terraform is set up.

### Development of Scripts and Playbooks

For the development of scripts and playbooks, the text editor Visual Studio Code with extensions was used to simplify the development process. This choice allows for easier code development. Using modular structures in Terraform can add complexity even for smaller projects because introducing additional layers of abstraction and managing modules can add extra complexity. Therefore, a single file structure was used for these projects to minimize complexity and simplify management.

To configure VMware with Terraform, the VMware vSphere Provider configuration is needed in the Terraform project to enable interaction with the VMware infrastructure. Using VMware resources, virtual machines, networks, and data stores can be created and managed. A copy of the template was then deployed in vCenter. This machine was named "UbuntuTemplate." It is important that the templates contain the necessary operating system and application settings. Additionally, SSH settings should be configured to establish a remote connection to the VMs and facilitate management. This machine was configured so that users can log in via SSH without a password. An RSA key for the SSH connection was created on the controller. To do this, execute the command:

```bash
ssh-keygen -t rsa -b 4096
```

Then, the public key was copied to the Ubuntu template with the command:

```bash
ssh-copy-id username@remote_host
```

If `ssh-copy-id` is not available, the following command can be used:

```bash
cat ~/.ssh/*.pub | ssh user@remote-system 'umask 077; cat >>.ssh/authorized_keys'
```

To allow root login without a password on the Ubuntu template, execute this command:

```bash
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
```

After automation, the configuration of this user should be secured again via the mail server for security reasons. These SSH settings are also required for later configuration with Ansible.

#### Developing Terraform Scripts

Terraform is an open-source tool for infrastructure automation developed by HashiCorp. It enables the creation, modification, and management of infrastructure resources on various cloud platforms and providers (such as AWS, Azure, Google Cloud, etc.) as well as local environments. Terraform uses Infrastructure as Code (IaC) to define infrastructure configurations in a simple and declarative language. These configurations are written in Terraform configuration files, which can be written in HashiCorp Configuration Language (HCL) or JSON format. Using Terraform, developers and DevOps teams can provision and manage infrastructure resources efficiently and reproducibly.

I first decided to develop Terraform scripts because our environment needs to be provisioned. First, the directories for the scripts were set up. Then, the scripts were developed with fixed values. First, the necessary VMware vSphere Provider configuration is defined, including the vSphere server, username, and password. Subsequently, data sources are used to retrieve information about the datacenter, datastore, host, network, and VM template.

The main resource defines the virtual machine, including the number of VMs, name, resources (CPU and memory), datastore, and network settings. Dynamic blocks are also used to customize the disk configuration of the VMs. A number of null resources are used to ensure that certain steps are completed before moving on to the next phase.

The last null resource executes a local execution provisioning script that initiates the execution of an Ansible playbook. This playbook is used to perform further configuration steps on the provisioned virtual machines.

As previously explained, our `main.tf` file for Terraform was created. However, to make our script more user-friendly and facilitate future value changes, either no changes should be made in the main script and instead changes should be made in the `variables.tf` file or a new variable file should be created. This would enable flexibility and easier management. To achieve this, a file named `variables.tf` should be created, specifying all the variables to be used.

However, for security reasons, variables like "vsphere_user," "vsphere_password," "vsphere_server," "linux_template_password" are not shared in the `variables.tf` file. Instead, a file named `terraform.tfvars` is created, and this data is securely stored there. Warning!: This file must not be publicly published on version control systems like GitHub or GitLab.

####  Developing Ansible Playbooks

Ansible is an open-source platform for automation, configuration management, and deployment. It provides a collaborative, lightweight, and comprehensive automation engine. Ansible simplifies the management of complex systems through simple configuration files and modular structures that can interact with many cloud providers and devices. It communicates with servers via the SSH protocol and defines actions through YAML files.

##### YAML (YAML Ain't Markup Language):

YAML is a human-readable data serialization format. It is used as a data representation and file format and is easy for humans to read and write. YAML can represent data structures such as lists, dictionaries, and complex objects. Tools like Ansible use YAML files to define configurations and automation steps. YAML files use an indentation-based syntax, so proper formatting of the file and correct use of indentation levels are important.

It was decided not to use a modular structure for the Ansible playbooks due to a specific infrastructure. First, a folder named "Ansible" was created, and the coding began with the `main.yml` file. Initially, the Ubuntu packages are updated in the playbook. Then, the hostnames for both servers are set to avoid any DNS issues in our test environment.

Afterwards, scripts are written to download Postfix and Mailutils. Mailutils is downloaded to send emails via the command line. A script section is then created to wait for 60 seconds to ensure the Postfix service works smoothly.

Next, the Jinja template, previously created for Postfix, is copied. In Ansible, it is used to create templates and dynamic content. This file contains the Postfix `main.cf` configurations. For example, the line `myhostname = {{ inventory_hostname }}` specifies Postfix's own hostname. `inventory_hostname` is a variable provided by Ansible and usually contains the server name. This allows Postfix to dynamically set its own hostname.

The line `mydestination = {{ inventory_hostname }}, localhost` specifies which hostnames are accepted by Postfix. In this case, `inventory_hostname` and `localhost` are accepted. This means that emails can be sent to these servers from `inventory_hostname` or `localhost`.

The line `relayhost = [mailserver-2.test.local]` indicates which other server Postfix should forward emails to. In this case, emails are forwarded to the server "mailserver-2.test.local."

The line `smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination` specifies the conditions under which Postfix should accept incoming emails. In this example, emails from local networks or authenticated users are accepted, while sending to unauthorized destinations is rejected. This provides a basic configuration that can be adjusted if necessary.

The next script section is for downloading Rspamd. The template file for Rspamd is then copied to both servers. The line `bind_socket` in the file is a setting used in Rspamd's configuration file, an email filtering and processing engine. This setting specifies the network address and port on which Rspamd should accept incoming connections.

Additionally, in the file /etc/rspamd/local.d/local.conf created by us, the following information is written to ensure that emails in HTML format are not accepted: `html: enable: true` and `javascript: false

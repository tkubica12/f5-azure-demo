# F5 and Azure enterprise demo

**WORK IN PROGRESS**

While a lot of born-in-cloud applications are built only with cloud-native resources such as PaaS (App Service / SQL DB / Cosmos DB), Azure Load Balancer, Azure Application Gateway, Azure VPN, Azure Traffic Manager, some applications beying moved to cloud as VM have more needs and might require enterprise solutions such as F5. Many enterprises are using F5 and want to build their architecture in a cloud in similar way. Azure and F5 are very well integrate to offer enterprise grade solutions.

## Why F5 and Azure
F5 offers a lot of capabilities that Azure customers might want to leverage in cloud as well. For example load-balancing capabilities are well positioned for traditional applications that require features like draining session and complicated health checks. With strong customization engine (iRules) customers have offen written their specific solutions and want them move to cloud. F5 also provides advanced security on network, protocol and application layer like WAF or DLP. Other capabilities include access management, global DNS balancing and more.

## How to build enterprise network in Azure with F5

Enterprise scenarios allow to build shared spoke VNET (can be in separate subscription) where all security and networking resources are deployed - VPN or Express Route connection to on-premises, AD, WSUS, deployment servers and virtual networking equipmenet like FW, NGFW, IPS, DLP, ADC. In our case F5. Typicaly this subscription is managed by networking and security team. While application can be deployed in the same subscription and VNET and role based access control used to set proper rights for application owners, enterprises often want to have separate subscription for each BU for example. Solution is to create separate hub VNET in separate subscription, connect to spoke VNET via VNET peering and force traffic to go throw spoke environment.

More details here: https://docs.microsoft.com/en-us/azure/networking/networking-virtual-datacenter

# Enterprise demo

In our enterprise demo we will use automated provisioning of environment based on ARM templates and Ansible including Azure networking, VM deployment, F5 deployment and parts of F5 configuration. Demonstration will include iApp Service Discovery to automatically add Azure resources based on tags automatically to server pools. 

## Prepare deployment server with Ansible and dependencies

```
sudo apt-get install python-pip -y
sudo pip install ansible[azure]
sudo pip install azure
sudo pip install packaging
sudo pip install msrestazure
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" |  sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli -y
```

## Deploy environment
First make sure you create secrets.rc file with all credentials and licenses. Format is noted in secrets.rc.example

```
. secrets.rc
ansible-playbook main.yaml
```

## How automation solution works
In this demo we will use Ansible playbook to orchestrate and fully automate F5 enterprise deployment. It is combination of deploying resources via ARM templates, Azure CLI 2.0 and F5 Ansible modules, all orchestrated via single Ansible playbook.

### Overall architecture
In this simplified demo we will deploy single VNET in Azure with multiple subnets and F5 point to internal, external and management subnet. Routing in internal subnet is pointed towards F5 as default gateway so all traffic going out of this subnet hits F5. In internal subnet we will deploy two web applications each with 3 instances (VMs) and use tagging on NICs so F5 iApp Service Discovery for Azure can automatically discover application nodes and add them to pool (and recheck this continuously so new when application is scaled out to more nodes those are automatically added to F5 configuration). Then we will automate other F5 configurations using Ansible such as creating virtual server for applications.

To simulate on-premises environment we will deploy additional separate VNET and F5 in Azure.

### Provide inputs via environmental variables
We do not want to store sensitive information in playbook itself so it is not accidentaly pushed to version control system. Look at example in secrets.rc.example and modify it to fit your needs.

One set of important secrets are login details to your Azure subscription using service principal. First you need to create service principal and key, which is service account that allows Ansible and Azure CLI to interact with Azure. Also you need to provide your tenant ID and subscription ID. Also automation will need to license F5 instances so make sure correct license key is provided.

### Creating resource group and networking
First two steps are to create resource group via Ansible Azure module and then use Ansible to deploy ARM template with networking and subnets.

### Deploying F5
In next step we will deploy F5 usv Ansible using official unmodified F5 template for 3 NIC configuration and BYOL (by downloading different template you can leverage pay-as-you-go model also). We provide key parameters to template including subnet names, license keys and IP addresses. Template will allocate 3 additional public IP address for use with our applications.

### Deploy on-premises simulated environment
Next set of steps is to deploy resource group, network and F5 to simulate on-premises environment.

### Deploying 2 web applications
In this step we will leverage ARM template that is designed to deploy instances of web server from custom image in Azure (web app is already preconfigured in this image). Input parameter includes number of instances to be deployed and template will automaticaly create that amount of VMs, NICs and disks.

Both applications will use NICs that are tagged F5pool:web1 or F5pool:web2. We will use those later in F5 configuration with iApp Service Discovery to automatically discover nodes and assign to F5 pool.

### Configure infrastructure firewall rules on F5 external NIC to allow our applications
Since we did not want to modify F5 template itself (so you can download latest version with no need to repeat modifications) we now need to enable ports 80 and 443 on external NIC to allow users to access applications.

### Enable IP Forwarding on F5 internal NIC
In order for F5 to receive traffic not directly target to it (which is how routing works) so F5 can function as gateway for workloads deployed in internal subnet, we will use Azure CLI to configure IP Forwarding.

### Change routing in internal subnet to use F5 as default gateway
Currently internal subnet is routed directly to Internet so in order for load-balancing via F5 to work, we would need to use SNAT. That would hide information about users and hurt our application logs + we want all traffic from internal subnet to reach Internet via F5 to provide additional protections. There we create routing table pointing to F5 and deploy to internal subnet

### Use Ansible to configure iApp service discovery
TO DO

Currently this is done via F5 GUI

### Use Ansible to create virtual servers
TO DO

Currently this is done via F5 GUI. We will use additional addresses (10.0.20.11, 10.0.20.12 and 10.0.20.13) as virtual server. Since Azure has public IP associated with those interfaces users will be able to access thos via Internet (Azure is providing 1:1 IP NAT).


# Easily secure application with F5 WAF and Azure Security Center

In this demo we will use simplified integrated scenario to secure web application running in Azure. We will use Azure Security Center to automatically deploy F5 WAF to protect application, simulate attack and demonstrate integration of F5 WAF with Security Center.

# Author
Tomas Kubica, linkedin.com/in/tkubica, Twittter: @tkubica

Blog in Czech: https://tomaskubica.cz

Looking forward for your feedback and suggestions!
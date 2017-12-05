# F5 and Azure enterprise demo

While a lot of born-in-cloud applications are built only with cloud-native resources such as PaaS (App Service / SQL DB / Cosmos DB), Azure Load Balancer, Azure Application Gateway, Azure VPN, Azure Traffic Manager, some applications beying moved to cloud as VM have more needs and might require enterprise solutions such as F5. Due to great integration and strong partnership between F5 and Microsoft, combination of F5 and Azure might be best option for your applications.

No matter whether your web application is traditional or modern, you might always want to protect it with Web Application Firewall making sure no L7 attack patterns make it throw, protocol level attacks are shielded or more sophisticated protections such as Data Leak Prevention are applied. F5 is trusted award winning WAF and is very well integrated to Azure Security Center.

Many enterprises are using F5 and want to build their architecture in a cloud in similar way. Azure and F5 in combinationoffer the best enterprise grade solutions for you applications.

- [F5 and Azure enterprise demo](#f5-and-azure-enterprise-demo)
    - [Why F5 and Azure](#why-f5-and-azure)
    - [How to build enterprise network in Azure with F5](#how-to-build-enterprise-network-in-azure-with-f5)
- [Enterprise demo: bring your complete app delivery and security environment to Azure with F5](#enterprise-demo-bring-your-complete-app-delivery-and-security-environment-to-azure-with-f5)
    - [Prepare deployment server with Ansible and dependencies](#prepare-deployment-server-with-ansible-and-dependencies)
    - [Deploy environment](#deploy-environment)
    - [How automation solution works](#how-automation-solution-works)
        - [Overall architecture](#overall-architecture)
        - [Provide inputs via environmental variables](#provide-inputs-via-environmental-variables)
        - [1st set of tasks: Ensure F5 in Azure environment is deployed (F5inAzure.yaml)](#1st-set-of-tasks-ensure-f5-in-azure-environment-is-deployed-f5inazureyaml)
            - [Creating resource group and networking](#creating-resource-group-and-networking)
            - [Deploying F5](#deploying-f5)
            - [Configure infrastructure firewall rules on F5 external NIC to allow our applications](#configure-infrastructure-firewall-rules-on-f5-external-nic-to-allow-our-applications)
            - [Enable IP Forwarding on F5 internal NIC](#enable-ip-forwarding-on-f5-internal-nic)
            - [Change routing in internal subnet to use F5 as default gateway](#change-routing-in-internal-subnet-to-use-f5-as-default-gateway)
            - [Get public IP addresses and configure DNS records in Azure DNS](#get-public-ip-addresses-and-configure-dns-records-in-azure-dns)
        - [2nd set of tasks: Ensure Azure web servers are deployed (webServers.yaml)](#2nd-set-of-tasks-ensure-azure-web-servers-are-deployed-webserversyaml)
            - [Deploying 2 web applications](#deploying-2-web-applications)
        - [3st set of tasks: Ensure F5 is configured for our apps (F5inAzureConfiguration.yaml)](#3st-set-of-tasks-ensure-f5-is-configured-for-our-apps-f5inazureconfigurationyaml)
            - [Use Ansible to configure iApp service discovery](#use-ansible-to-configure-iapp-service-discovery)
            - [Use Ansible to create virtual servers](#use-ansible-to-create-virtual-servers)
            - [Test web1 and web2 is accessible on their public endpoints via F5](#test-web1-and-web2-is-accessible-on-their-public-endpoints-via-f5)
        - [4th set of tasks: Ensure F5 on premises (simulated in Azure) is deployed (F5onPrem.yaml)](#4th-set-of-tasks-ensure-f5-on-premises-simulated-in-azure-is-deployed-f5onpremyaml)
            - [Deploy on-premises simulated environment](#deploy-on-premises-simulated-environment)
        - [5st set of tasks: Make sure bursting environment with app and iApp Application Connector exists (bursting.yaml)](#5st-set-of-tasks-make-sure-bursting-environment-with-app-and-iapp-application-connector-exists-burstingyaml)
            - [Separate resource group, network and subnet](#separate-resource-group-network-and-subnet)
            - [Depoy web application](#depoy-web-application)
            - [Deploy and start F5 cloud proxy](#deploy-and-start-f5-cloud-proxy)
- [Easily secure application with F5 WAF and Azure Security Center](#easily-secure-application-with-f5-waf-and-azure-security-center)
    - [Create VM with web application](#create-vm-with-web-application)
    - [See application recommendation in Azure Security Center and deploy F5](#see-application-recommendation-in-azure-security-center-and-deploy-f5)
    - [Simulate attack and see alerts in Azure Security Center](#simulate-attack-and-see-alerts-in-azure-security-center)
- [Author](#author)

## Why F5 and Azure
F5 offers a lot of capabilities that Azure customers might want to leverage in cloud as well. For example load-balancing capabilities are well positioned for traditional applications that require features like draining session and complicated health checks. With strong customization engine (iRules) customers have offen written their specific solutions and want them move to cloud. F5 also provides advanced security on network, protocol and application layer like WAF or DLP. Other capabilities include access management, global DNS balancing and more.

## How to build enterprise network in Azure with F5

Enterprise scenarios allow to build shared spoke VNET (can be in separate subscription) where all security and networking resources are deployed - VPN or Express Route connection to on-premises, AD, WSUS, deployment servers and virtual networking equipmenet like FW, NGFW, IPS, DLP, ADC. In our case F5. Typicaly this subscription is managed by networking and security team. While application can be deployed in the same subscription and VNET and role based access control used to set proper rights for application owners, enterprises often want to have separate subscription for each BU for example. Solution is to create separate hub VNET in separate subscription, connect to spoke VNET via VNET peering and force traffic to go throw spoke environment.

More details here: https://docs.microsoft.com/en-us/azure/networking/networking-virtual-datacenter

# Enterprise demo: bring your complete app delivery and security environment to Azure with F5

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
sudo pip install bigsuds
sudo pip install deepdiff
sudo pip install f5-sdk
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

### 1st set of tasks: Ensure F5 in Azure environment is deployed (F5inAzure.yaml)
In this series of tasks stored in F5inAzure.yaml we will deploy our Azure networking environment, F5 virtual applicance and configure our environment to modify Azure firewalling and routing rules to point to F5.

#### Creating resource group and networking
Let's create resource group via Ansible Azure module and then use Ansible to deploy ARM template with networking and subnets.

#### Deploying F5
In next step we will deploy F5 usv Ansible using official unmodified F5 template for 3 NIC configuration and BYOL (by downloading different template you can leverage pay-as-you-go model also). We provide key parameters to template including subnet names, license keys and IP addresses. Template will allocate 3 additional public IP address for use with our applications.

#### Configure infrastructure firewall rules on F5 external NIC to allow our applications
Since we did not want to modify F5 template itself (so you can download latest version with no need to repeat modifications) we now need to enable ports 80 and 443 on external NIC to allow users to access applications.

#### Enable IP Forwarding on F5 internal NIC
In order for F5 to receive traffic not directly target to it (which is how routing works) so F5 can function as gateway for workloads deployed in internal subnet, we will use Azure CLI to configure IP Forwarding.

#### Change routing in internal subnet to use F5 as default gateway
Currently internal subnet is routed directly to Internet so in order for load-balancing via F5 to work, we would need to use SNAT. That would hide information about users and hurt our application logs + we want all traffic from internal subnet to reach Internet via F5 to provide additional protections. There we create routing table pointing to F5 and deploy to internal subnet

#### Get public IP addresses and configure DNS records in Azure DNS
In this demo we use approach of public IP per F5 service. In this tasks we are gathering actual public IP addresses as assigned by Azure and setting up A records in Azure DNS with our own domain.

### 2nd set of tasks: Ensure Azure web servers are deployed (webServers.yaml)
In this series of tasks we will deploy two web applications with 3 instances each. We will place it to internal subnet and use tagging for service discovery.

#### Deploying 2 web applications
In this step we will leverage ARM template that is designed to deploy instances of web server from custom image in Azure (web app is already preconfigured in this image). Input parameter includes number of instances to be deployed and template will automaticaly create that amount of VMs, NICs and disks.

Both applications will use NICs that are tagged F5pool:web1 or F5pool:web2. We will use those later in F5 configuration with iApp Service Discovery to automatically discover nodes and assign to F5 pool.

### 3st set of tasks: Ensure F5 is configured for our apps (F5inAzureConfiguration.yaml)
In this step we want to configure dynamicaly discovered backend pool and virtual server in F5.

#### Use Ansible to configure iApp service discovery
In first two tasks we are configuring iApp Service Discovery with Azure credentials to automatically discover pool members. In first case identified by tag F5pool:web1 and F5pool:web2 in second app. Also health check will be created.

#### Use Ansible to create virtual servers
We will use additional addresses (10.0.20.11, 10.0.20.12 and 10.0.20.13) as virtual server. Since Azure has public IP associated with those interfaces users will be able to access thos via Internet (Azure is providing 1:1 IP NAT). This Ansible task is configuring virtual server for our web1 and web2 applications.

#### Test web1 and web2 is accessible on their public endpoints via F5
Our playbook will now test we are able to access public endpoints throw F5 from our deployment server and get responses from our applications.

### 4th set of tasks: Ensure F5 on premises (simulated in Azure) is deployed (F5onPrem.yaml)
In this series of task we deploy simulation of on-premises environment with F5.

#### Deploy on-premises simulated environment
Next set of steps is to deploy resource group, network and F5 to simulate on-premises environment.

### 5st set of tasks: Make sure bursting environment with app and iApp Application Connector exists (bursting.yaml)
Prepare demo of bursting example - creating web nodes in Azure together with F5 cloud proxy to quickly add performance to on-premises application without going throw full enterprise-grade deployment with network interconnection, F5 in cloud etc.

#### Separate resource group, network and subnet
First we will deploy separate environment - resource group, network and subnet.

#### Depoy web application
Next we are going to deploy 3 instances of web application.

#### Deploy and start F5 cloud proxy
In order for F5 to create TLS tunnel from on-premises to cloud we need to have Linux VM with public IP address, installed Docker engine and run Docker container with F5 proxy. This is automated using deployment of Ubuntu 16.04 VM and running VM extension with custom script to install Docker, download image and run it.

F5 iApp Application Connector need to have access to Azure in order to provide node discovery. This is handled by configuration file with credentials that need to be mapped to container as volume. We pass credentials to extension script as arguments and script creates file in proper format and map it to container.

# Easily secure application with F5 WAF and Azure Security Center

In this demo we will use simplified integrated scenario to secure web application running in Azure. We will use Azure Security Center to automatically deploy F5 WAF to protect application, simulate attack and demonstrate integration of F5 WAF with Security Center.

## Create VM with web application
First create VM with web application and make sure some client is accessing it, so Azure Security Center properly discovers this app.

## See application recommendation in Azure Security Center and deploy F5
After brief moment Azure Security Center will discover your web app and recommend protecting it with F5. Select F5 and fill in all the details. ACS will automatically deploy F5 in configure WAF. There will be Azure Load Balancer in front of F5 automatically created and applications you choose to protect will get public IP assigned there including standard ports (80/443). F5 is configured by ACS to listen on non-standard port so single F5 interface can be used to protect multiple applications and Azure LB is passing traffic to that port. F5 that provides application protection and pass traffic to actual IP address with our application.

After successful provisioning make sure your web application can no longer be accessed on original IP, only throw Azure LB that points to F5 WAF. Also you might need to change your DNS records.

## Simulate attack and see alerts in Azure Security Center
Now if we have some form with fields in our web application, we can easily simulate primitive attack to see F5 protects our application and Azure Security Center provides overall view into security including F5 data. Pass something like ' OR 1=1 to your field (SQL injection attempt) and check results.

# Author
Tomas Kubica, https://linkedin.com/in/tkubica, Twittter: https://twitter.com/tkubica

Blog in Czech: https://tomaskubica.cz

Looking forward for your feedback and suggestions!
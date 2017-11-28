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

```
. secrets.rc
ansible-playbook main.yaml
```

# Easily secure application with F5 WAF and Azure Security Center

In this demo we will use simplified integrated scenario to secure web application running in Azure. We will use Azure Security Center to automatically deploy F5 WAF to protect application, simulate attack and demonstrate integration of F5 WAF with Security Center.

# Author
Tomas Kubica, linkedin.com/in/tkubica, Twittter: @tkubica

Blog in Czech: https://tomaskubica.cz

Looking forward for your feedback and suggestions!
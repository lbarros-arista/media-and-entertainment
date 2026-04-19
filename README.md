# Arista M&E SMPTE 2110 Real Time Network with MCS controller

This repo includes a SMPTE 2110 Real Time datacenter network with a RED and a BLUE spine and RED and BLUE leafs.

## Introduction

This is a test network to experiment with a SMPTE 2110 Real Time network and Arista MCS controller.
---
## Device Credentials

> username: ansible  
> password: ansible

## Topology

![SMPTE 2110 Real Time Network](/images/topology.clab.png)

## Instructions to setup the lab

### OPTIONAL - To connect this lab to CloudVision we need to follow certain steps:

1. We need to generate a service account so that AVD can push configs to CloudVision

   Follow the steps described here [Steps to create service accounts on CloudVision](https://avd.arista.com/6.1/ansible_collections/arista/avd/roles/cv_deploy/index.html)

   Steps to create service accounts in CloudVision:

   **Settings → Access Control → Service Accounts → click + New Service Account**

   Save the token in a password management application such as Password1 for example, because the token will disappear from the screen.

   With the Service Token generated at (1), we need to encrypt this with Ansible Vault.

   So in your devcontainer running AVD in the Terminal you can do this:

   *ansible-vault encrypt_string 'PUT YOUR TOKEN STRING HERE' --name 'CV_API_TOKEN' >> ./clab/cvp-ansible-vault.txt*

   **NOTE:** You don't need file **./clab/cvp-ansible-vault.txt**. You will just need the encypted token hash, the file is just a way of backing up your encrypted token hash.

   Copy file **./avd/playbooks/cvaas_deploy_geberic.yml** to **./avd/playbooks/cvaas_deploy_YOUR_NAME.yml**

   Then update the encrypted token (everything below **"$ANSIBLE_VAULT;1.1;AES256")** to **./avd/playbooks/cvaas_deploy_YOUR_NAME.yml**

   Add **cvaas_deploy_YOUR_NAME.yml** to your **.gitignore** file

   Finally change the Makefile aliases **"deploy-cvaas-X"** to point to your new playbook with your token **"cvaas_deploy_YOUR_NAME.yml"**

2. Generate a token to register devices (cEOS-lab containers in this case) on CloudVision

   In CloudVision go to **Devices → Device Registration → Generate Token**

   Save the token in a password management application such as Password1 for example, because the token will disappear from the screen.

   For more info please refer to the CloudVision Help Center [Onboard Devices](https://www.arista.io/help/articles/ZGV2aWNlcy5kZXZpY2VSZWdpc3RyYXRpb24ub25ib2FyZA==#onboard-devices)

   Then save the token generated in (2) on a text file without extension in your cloned repo local directory **./clab/cv-onboarding-token**

   This file will not be syched to the GitHub repo because it's listed in the **.gitignore** file

   This directory location is used in the Containerlab topology file to mount the onboarding token in the flash: of the container at boot time (see "binds" section of the topology.clab.yml file)

## Instructions to run Lab

### Uploading a cEOS image to the devcontainer

#### Method 1 - Automated

Arista container images are automatically downloaded in the devcontainer by the "eos-downloader" python module, provided the ARTOKEN variable is passed.

You can generate an Arista Token to download software at ***www.arista.com > Welcome! NAME > My Profile***

![Arista Software Downloads Token](/images/token.png)

Depending on how you set up your environment passing this variable is done in different ways.

#### Method 2 - Manual

Alternatively cEOS-lab image can be ***manually*** downloaded from the [Arista Software Download Site](https://www.arista.com/en/support/software-download)

Then moved manually to the devcontainer:

```
user@hostname ~ % docker container ls
CONTAINER ID   IMAGE                                                                          COMMAND                  CREATED        STATUS        PORTS                                             NAMES
7af9aa10e7cb   vsc-m-and-e-c9ac80222b0cdbb67a7cd8806ef20a396387f4da33ff3ff00a2965f32f71c087   "/bin/sh -c 'echo Co…"   17 hours ago   Up 17 hours   0.0.0.0:50081->50080/tcp, [::]:50081->50080/tcp   great_chaum

user@hostname ~ % docker cp ./cEOSarm-lab-4.35.3F.tar 7af9aa10e7cb:/workspaces/m-and-e/
```

Then inside the container import it and tag it to match the image name in the topology.clab.yml file.

For example:

```
avd ➜ /workspaces/m-and-e (main) $ docker import cEOSarm-lab-4.35.3F.tar arista/ceos:4.35.3F
sha256:f16d467e006cbbd7b7c7d8dcfe5f621c61549144171d3c7ad85df41c0d739413

avd ➜ /workspaces/m-and-e (main) $ docker image ls

IMAGE                                         ID             DISK USAGE   CONTENT SIZE   EXTRA
arista/ceos:4.35.3F                           5b2d33e146a3       3.75GB          906MB    U   
ghcr.io/kaelemc/wireshark-vnc-docker:latest   60f02a02a008        743MB          190MB        
ghcr.io/siemens/ghostwire:latest              a01295061e2d       48.7MB         13.5MB    U   
ghcr.io/siemens/packetflix:latest             78bddc205684        203MB           43MB    U   

```

### Build AVD Configs with

```shell
make build
```

### Start the lab with

There are 2 aliases in the Makefile, depending how you desire to start the lab.

To start a clean lab, run this command:

```shell
make start-clean
```

To start a lab using all the containerlab files previously saved (Requires having stopped the lab with "make stop")

```shell
make start
```

Please check the make file:

```
.PHONY: start
start: 
	sudo containerlab deploy --topo $(CURRENT_DIR)/clab/topology.clab.yml --max-workers 21 --timeout 10m

.PHONY: start-clean
start-clean: ## Deploy ceos lab with --reconfigure flag
	sudo containerlab deploy --topo $(CURRENT_DIR)/clab/topology.clab.yml --max-workers 21 --timeout 10m --reconfigure
```

### To deploy the configs generated with AVD directly via eAPI to the devices

```shell
make deploy-eapi
```

### To deploy the configs generated with AVD directly via eAPI to the devices

If you want to deploy the AVD configs to CloudVision instead of directly via eAPI

```shell
make deploy-cvaas
```

### To stop de lab

There are 2 aliases in the Makefile, depending how you desire to start the lab.

```
make stop-clean
```

This will save the running configs and retain all the containerlab files for the flash: etc.

```
make stop
```

Please check the make file:

```
.PHONY: stop
stop: save
	sudo containerlab destroy --topo $(CURRENT_DIR)/clab/topology.clab.yml --graceful --keep-mgmt-net

.PHONY: stop-clean-mgmt
stop-clean-mgmt: ## Destroy ceos lab and cleanup management network
	sudo containerlab destroy --topo $(CURRENT_DIR)/clab/topology.clab.yml --cleanup

<snip>

.PHONY: save
save:
	sudo containerlab save --topo $(CURRENT_DIR)/clab/topology.clab.yml
```


# Initiate MCAST Streams on media-hosts

```
    iperf -s -u -B 239.1.1.1%vlan100 -H 10.10.100.3 -i 1
iperf -c 232.1.1.1 -B 172.16.0.1 -u -t 3600 -l 1350 -T 10 -b 100M
iperf -c 232.1.1.1 -B 172.16.0.3 -u -t 3600 -l 1350 -T 10 -b 100M
```


# MCS API Calls JSON Payload Example

## Register Sender

```
{
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.1",
            "bandwidth": 100,
            "bwType": "m",
            "inIntfID": "00:1c:73:47:be:21-Ethernet2",
            "label": "ME-Demo",
            "applyPolicy": true,
            "dscp": 46,
            "tc": 6
        }
    ],
    "flow-action": "addSenders",
    "transactionID": "GS#1",
    "trackingID": 1
}
```

## Register Receiver

```
{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.1",
            "outIntfID": [
                "001c.7304.0032-Ethernet2"
            ]
        }
    ]
}
```

# If you want to do an API call directly from the Visual Studio Code Terminal

## Example for RED network

### Send API call to RED MCS registerin 

```
curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5280/mcs/multicast/senders' \
--header 'Content-Type: application/json' \
--data '{
    "data": [
        {
            "destinationIP": "232.1.1.1",
              "sourceIP": "172.16.0.1",
            "bandwidth": 100,
            "bwType": "m",
            "inIntfID": "001c.7347.be21-Ethernet2",
            "label": "ME-Demo",
            "applyPolicy": true,
            "dscp": 46,
            "tc": 6
        }
    ],
    "flow-action": "addSenders",
    "transactionID": "GS#1",
    "trackingID": 1
}'

curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5280/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.3",
            "outIntfID": [
                "001c.7326.9b2b-Ethernet2"
            ]
        }
    ]
}
'
```


```
curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5280/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.1",
            "outIntfID": [
                "001c.7304.0032-Ethernet2"
            ]
        }
    ]
}
'
```

### Send API call to RED MCS registering receiver on red-rt-leaf2 interface Ethernet3 interested in (S,G) group (172.16.0.1,232.1.1.1)

```
curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5280/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.1",
            "outIntfID": [
                "001c.7304.0032-Ethernet3"
            ]
        }
    ]
}
'
```

### Send API call to 

```
curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5281/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.3",
            "outIntfID": [
                "001c.7326.9b2b-Ethernet3"
            ]
        }
    ]
}
'
```

## Example for BLUE network

```
curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5281/mcs/multicast/senders' \
--header 'Content-Type: application/json' \
--data '{
    "data": [
        {
            "destinationIP": "232.1.1.1",
              "sourceIP": "172.16.0.3",
            "bandwidth": 100,
            "bwType": "m",
            "inIntfID": "001c.73cb.ea89-Ethernet2",
            "label": "ME-Demo",
            "applyPolicy": true,
            "dscp": 46,
            "tc": 6
        }
    ],
    "flow-action": "addSenders",
    "transactionID": "GS#1",
    "trackingID": 1
}'

curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5281/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.3",
            "outIntfID": [
                "001c.7326.9b2b-Ethernet2"
            ]
        }
    ]
}
'

curl --user ansible:ansible --insecure --location 'https://0.0.0.0:5281/mcs/multicast/receivers' \
--header 'Content-Type: application/json' \
--data '{
    "flow-action": "addReceivers",
    "transactionID": "ME-Demo",
    "trackingID": 1,
    "data": [
        {
            "destinationIP": "232.1.1.1",
            "sourceIP": "172.16.0.3",
            "outIntfID": [
                "001c.7326.9b2b-Ethernet3"
            ]
        }
    ]
}
'
```

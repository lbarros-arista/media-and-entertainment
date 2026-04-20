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

First fork this repo or clone it.

It is mandatory if you intend to connect this lab to CloudVision to hardcode your devices' serial numbers.

What happens if you do not do this? Then every time you spin the lab again random S/N mumbers will be generated and you end up with a lot of garbage in CloudVision if you destroy your machines each time.

In the **./clab/sn** folder you have files that are mounted on every container at startup for this purpose.

Please generate random unique numbers in this format:

S/Ns are 32 caracters long.

```
SERIALNUMBER=39A359DBENTERTHESERIALNUMBERHERE
SYSTEMMACADDR=001c.73xx.xxxx
```

Alternatively you can start the lab the first time without hardcoding the S/Ns and then copy the reandomly generated S/N and system MAC numbers from the **show version** of the machines once they are up and running.

If you do this you need to first comment the lines out mounting the serial number files in the **topology.clab.yml** before starting the lab:

```
      binds:
        # - ../clab/sn/blue-mcs.txt:/mnt/flash/ceos-config:ro
        - ../clab/cv-onboarding-token:/mnt/flash/cv-onboarding-token:ro
        - ../clab/eos-intf-mapping/ceos-lab_EosIntfMapping.json:/mnt/flash/EosIntfMapping.json:ro
```

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

   Then update the encrypted token in the playbook.
   
   This means Add everything below **"$ANSIBLE_VAULT;1.1;AES256"** to **./avd/playbooks/cvaas_deploy.yml**

   ```
   ---

   - name: Configuration deployment
     hosts: FABRIC
     connection: local
     gather_facts: false
     tasks:
       - name: Deploy configurations and tags to CloudVision
         ansible.builtin.import_role:
           name: arista.avd.cv_deploy
         vars:
           cv_server: www.cv-prod-euwest-2.arista.io
           cv_skip_missing_devices: true
           cv_submit_workspace: false
           cv_run_change_control: false
           cv_configlet_name_template: "AVD-${hostname}"
           cv_register_detailed_results: true
           cv_token: !vault |
                     $ANSIBLE_VAULT;1.1;AES256
                     "ADD YOUR CVAAS TOKEN HERE ENCRYPTED WITH ANSIBLE VAULT"


   ```

   ### Important!

   Add **cvaas_deploy.yml** to your **.gitignore** file if you intend to share this repo with anyone or if for example you have a public repo. It's an encrypted hash but always better safe than sorry!

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

On my Mac I have Docker Desktop running and pass the variable to the devcontainer in this way:

```
username@hostname ~ % pwd
/Users/username

username@hostname ~ % cat .zshrc
# export ARTOKEN value
export ARTOKEN=SOME-PERSONAL-TOKEN-VALUE
username@hostname ~ % 
```

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


# Initiate MCAST Streams on media-hosts1 as an Example

```
iperf -c 232.1.1.1 -B 172.16.0.1 -u -t 3600 -l 1350 -T 10 -b 100M
```

For Example:

```
media-host1#bash

Arista Networks EOS shell

[ansible@media-host1 ~]$ iperf -c 232.1.1.1 -B 172.16.0.1 -u -t 3600 -l 1350 -T 10 -b 100M
------------------------------------------------------------
Client connecting to 232.1.1.1, UDP port 5001
Sending 1350 byte datagrams, IPG target: 103.00 us (kalman adjust)
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
[  1] local 172.16.0.1 port 60914 connected with 232.1.1.1 port 5001
[ ID] Interval       Transfer     Bandwidth
[  1] 0.00-3600.00 sec  43.9 GBytes   105 Mbits/sec
[  1] Sent 34952528 datagrams
```

If you would like to emulate an IGMPv3 join:

```
iperf -s -u -B 239.1.1.1%_et1 -H 172.16.0.1 -i 1
```

For Example:

```
[ansible@media-host2 ~]$ ifconfig
_et1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
        inet 172.16.0.5  netmask 255.255.255.254  broadcast 255.255.255.255
        ether 00:1c:73:32:a2:e0  txqueuelen 1000  (Ethernet)
        RX packets 1192702  bytes 409399415 (390.4 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1895  bytes 502149 (490.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

_et2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9000
        inet 172.16.0.7  netmask 255.255.255.254  broadcast 255.255.255.255
        ether 00:1c:73:32:a2:e0  txqueuelen 1000  (Ethernet)
        RX packets 958587  bytes 83915368 (80.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1894  bytes 503791 (491.9 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[ansible@media-host2 ~]$ iperf -s -u -B 239.1.1.1%_et1 -H 172.16.0.1 -i 1
------------------------------------------------------------
Server listening on UDP port 5001
Joining multicast (S,G)=172.16.0.1,239.1.1.1 w/iface _et1
Server set to single client traffic mode (per multicast receive)
UDP buffer size:  208 KByte (default)
------------------------------------------------------------
```

On the RT Leaf:

```
red-rt-leaf2#show ip igmp membership 
Interface----------------Group Address----IncludeSrc----------ExcludeSrc----------
Ethernet2                239.1.1.1        172.16.0.1                              
```

---

# MCS API Calls JSON Payload Example

[Please refer to Postman CVX-MCS Collection](https://documenter.getpostman.com/view/195675/SVtR2qeA)

Note that the **"inIntfID": "00:1c:73:47:be:21-Ethernet2"** is the system MAC of the target and the interface.

To register senders, the action is **"flow-action": "addSenders",**

To deregister senders, the action is **"flow-action": "delSenders",**

Analogously, to reguster receivers the action is **"flow-action": "addReceivers",** and to deregister **"flow-action": "delReceivers",**



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

### Send API call to RED MCS registering SENDER on red-rt-leaf1 interface Ethernet2 (S,G) group (172.16.0.1,232.1.1.1)

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
            "inIntfID": "001c.7347.acac-Ethernet2",
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
```

### Send API call to RED MCS registering receiver on red-rt-leaf2 interface Ethernet2 interested in (S,G) group (172.16.0.1,232.1.1.1)

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
                "001c.7304.efef-Ethernet2"
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
                "001c.7304.efef-Ethernet3"
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
            "inIntfID": "001c.73cb.abab-Ethernet2",
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
                "001c.7326.dede-Ethernet2"
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
                "001c.7326.dede-Ethernet3"
            ]
        }
    ]
}
'
```

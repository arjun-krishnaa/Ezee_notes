# Centralized SSH Access for Multiple AWS EC2 Instances

This guide explains **step by step** how to manage multiple EC2 instances using **one SSH key** and perform updates on all servers **from a single EC2 instance**.

---

## Objective

* Use **one SSH key** for all EC2 instances
* Access **EC2-2 and EC2-3 from EC2-1**
* With **username/password login**
* Perform updates and changes centrally

---

## Architecture Overview

```
Your Laptop
   |
   | (SSH key)
   v
EC2-1 (Admin / Jump Server)
   |
   | (same SSH key)
   v
EC2-2
EC2-3
```

---

## Prerequisites

* 3 EC2 instances running (Ubuntu or Amazon Linux)
* SSH access to EC2-1
* Username:

  * Ubuntu → `ubuntu`
  * Amazon Linux → `ec2-user`
* Password access currently enabled on EC2-2 and EC2-3

---

## Step 1: Login to EC2-1 (Admin Server)

From your local machine:

```bash
ssh ubuntu@EC2-1-IP
```

Switch to the home directory:

```bash
cd ~
```

---

## Step 2: Generate a Common SSH Key on EC2-1

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/common_ec2_key
```

* Enter **password** for the key.

This creates:

* Private key: `~/.ssh/common_ec2_key`
* Public key: `~/.ssh/common_ec2_key.pub`

---

## Step 3: Create user and Place key in servers
#### Will try two methods:
1. Create a new user and add the key
2. Change the Ubuntu (root) key

Server 2 username: **stageuser**
Server 3 username: **ubuntu**

#### Login to Server-2 and Create New User
```
sudo useradd stageuser
sudo passwd qwer321 (random password)
```
For "stageuser" don't give "sudo" permissions.
#### Prepare SSH Directory for New User
```
sudo mkdir -p /home/stageuser/.ssh
sudo chmod 700 /home/stageuser/.ssh
sudo chown stageuser:stageuser /home/stageuser/.ssh
```
Copy and paste Public key from Server 1 from **~/.ssh/common_ec2_key.pub**
#### Add Public Key
```
vi /home/stageuser/.ssh/authorized_keys
```
Paste the key
```
chmod 600 /home/stageuser/.ssh/authorized_keys
chown stageuser:stageuser /home/stageuser/.ssh/authorized_keys
```
## Step 4: Replace Ubuntu (root) key
#### Login to Server-2 and Change directory
```
cd /home/ubuntu/.ssh
```
#### Edit "authorized_keys" file and paste the generated key
**Ensure the below commands**
```
sudo chmod 700 /home/ubuntu/.ssh
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh
```
**Add Public Key**
```
vi home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
```
---

## Step 5: Configure SSH for Easy Access

Edit SSH config file in Server 1:

```bash
nano ~/.ssh/config
```

Add
Host stage                          - **Nickname to call server** 
HostName 172.31.9.91                - **Instance private or private ip [prefer - private ip]**
User stageuser                      - **Mention username of server (ex. ubuntu, ec2-user, stageuser)**
IdentityFile ~/.ssh/common_ec2_key  -   **Mention key location** 



```ini
Host stage
    HostName 172.31.9.91
    User stageuser
    IdentityFile ~/.ssh/common_ec2_key

Host bits
    HostName 172.31.8.133
    User ubuntu
    IdentityFile ~/.ssh/common_ec2_key
```

Set permissions:

```bash
chmod 600 ~/.ssh/config
```

---

## Step 6: Disable Password Authentication (Security Best Practice)

On EC2-2 and EC2-3:

```bash
sudo nano /etc/ssh/sshd_config
```

Update values:

```ini
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH service:

```bash
sudo systemctl restart ssh
```

⚠️ Ensure key-based login works before doing this.


Now connect using:

```bash
ssh stage
ssh bits
```

---

## Step 7: Update Servers from EC2-1

### Manual Update

```bash
ssh stage "sudo apt update && sudo apt upgrade -y"
ssh bits "sudo apt update && sudo apt upgrade -y"
```


---

##  Final Outcome

*  One SSH key for all EC2 instances
*  Centralized administration from EC2-1
*  Passwordless & secure access
*  Easy automation & scaling

---


**End of Document**

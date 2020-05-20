### SHAMAN

Shaman is a container that includes a group of tools often used to run automatization tasks on private clouds, mainly VMWare environments. It's based on the Alpine variant of the docker image of PowerShell and includes other tools.

The list of the most relevant tools are:

- Base Image: Alpine 3.11
- Relevant Packages:
     - Powershell 7.0.0 LTS
     - PowerCLI 12.0.0
     - Terraform 0.12.16
     - Go 1.13.4
     - Ovftool 4.4.0
     - GOVC 0.22.1
     - Ansible 2.9.7
     - Python 3.8.2
     - JQ v20191114
     - Vim
     - Git
     - sshpass
     - qemu-img


To build, download the OVFTool distribution from the VMware site, then extract the files from the installation file:

sh ./VMware-ovftool-*-lin.x86_64.bundle --extract ./ovftoolfiles/

then you copy the ./ovftoolfiles/ content

docker build -t shaman . 

Usage example:

docker run --rm -it rolandoanton/shaman:latest bash





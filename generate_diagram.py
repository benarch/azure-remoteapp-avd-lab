#!/usr/bin/env python3
"""
Generate Azure Virtual Desktop architecture diagram using the diagrams library.
Uses Azure icons to match the deployment components.
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.azure.compute import VM, VMWindows
from diagrams.azure.network import VirtualNetworks, Subnets, NetworkSecurityGroupsClassic
from diagrams.azure.identity import Users
from diagrams.azure.general import Resourcegroups
from diagrams.azure.compute import Disks
from diagrams.onprem.client import User, Users as OnPremUsers

# Graph attributes for better layout
graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "ortho",
}

node_attr = {
    "fontsize": "12",
}

edge_attr = {
    "fontsize": "10",
}

with Diagram(
    "Azure Virtual Desktop - RemoteApp Lab",
    filename="avd-architecture",
    outformat="png",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    # Users accessing the environment
    with Cluster("Client Access"):
        users = OnPremUsers("Local Users\n(avduser1-4)")
        windows_app = User("Windows App\n(macOS/Web)")
    
    with Cluster("Azure Subscription"):
        with Cluster("Resource Group\nrg-avd-lab1-dev"):
            
            # AVD Control Plane
            with Cluster("AVD Control Plane"):
                from diagrams.azure.compute import CloudServicesClassic
                host_pool = CloudServicesClassic("Host Pool\nhpl-avd-lab1")
                workspace = CloudServicesClassic("Workspace\nws-avd-lab1")
                
                with Cluster("Application Groups"):
                    from diagrams.azure.compute import CloudServicesClassic as AppGroup
                    desktop_ag = AppGroup("Desktop\nApp Group")
                    remoteapp_ag = AppGroup("RemoteApp\nApp Group")
            
            # Networking
            with Cluster("Virtual Network\n192.168.100.0/22"):
                nsg = NetworkSecurityGroupsClassic("NSG")
                
                with Cluster("AVD Subnet\n192.168.100.0/24"):
                    # Session Hosts
                    session_host = VMWindows("Session Host\nsh-dev-vm-1")
                    os_disk = Disks("OS Disk\nPremium SSD")
                
                with Cluster("Bastion Subnet\n192.168.101.0/24"):
                    from diagrams.azure.network import Subnets as BastionSubnet
                    bastion_reserved = BastionSubnet("Reserved\nfor Bastion")
    
    # Connections
    users >> Edge(label="RDP") >> windows_app
    windows_app >> Edge(label="HTTPS") >> workspace
    workspace >> host_pool
    host_pool >> desktop_ag
    host_pool >> remoteapp_ag
    desktop_ag >> session_host
    remoteapp_ag >> session_host
    session_host >> os_disk
    nsg >> session_host

print("Diagram generated: avd-architecture.png")

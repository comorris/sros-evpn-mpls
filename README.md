# SR OS EVPN-MPLS Configuration Reference Guide

This page provides the basic step-by-step configuration required to migrate from RSVP-TE MPLS based VPLS services to EVPN-MPLS, using Segment Routing as the underlay transport.  

| Contributors | Handle |
|---|---|
| Cory Morris | [comorris](https://github.com/comorris) |


All configurations are in MD-CLI flat format. Reference chassis is the ixr-s and software version is SR OS 24.10.R3. Use `show system info` command to verify your router's chassis model and software version.

The following services are covered in this guide:


- [SR-MPLS](#SR-MPLS)
- [EVPN-MPLS](#EVPN-MPLS)

# Topology, IPv4 Addressing and Description

We will be using the below topology with 3 routers, 1 spine router and 3 linux hosts, each connected to 1 leaf.

Each router will have a base configuration with OSPF underlay, RSVP-TE and VPLS already configured.  Configuration examples for converting to EVPN-MPLS with Segment Routing using OSFP (SRO-OSPF) will be shown below.  Only the VPLS services on Leaf1 and Leaf2 will be converted to VPLS over EVPN-MPLS, while leaf 3 will remain as VPLS over MPLS to show interworking.  The majority of the configuration will be done on Leaf1 and Leaf2.  

In the final step, we will configure all leaf routers to utilize SR-OSPF for the transport tunnels to fully convert the network to SR-OSPF and showcase interoping with other VPLS over MPLS services.

The physical and logical topology is shown below:

## Physical Topology

<img src="./images/physical-topology.png" width="100%"/>

## Initial Logical Topology for VPLS over MPLS

<img src="./images/rsvp.png" width="100%"/>

## Ending Logical Topology for VPLS over EVPN-MPLS w/SR-OSPF

The goal of this lab is end up with a fully functioning EVPN-MPLS network using SR-OSPF for the MPLS transport
<img src="./images/evpn-mpls.png" width="100%"/>

# vSIM image

The containerlab topology uses a vSIM image that is containerized using the vrnetlab project. Follow the instructions on the [Nokia SR OS (vSIM)](https://containerlab.dev/manual/kinds/vr-sros/) page to create and load the image intto your docker environment.
Contact your Account team to obtain a vSIM license.

# Deploying the lab

Clone this repo to your local environment:

```
git clone https://github.com/comorris/sros-evpn-mpls.git
```

Navigate to the directory for this lab:

```
cd sros-evpn-mpls
```

Ensure a vSIM license is copied into the root of the folder

Modify the Topology file:

First modify the topology file to give it a unique name.  Since multiple copies of this lab will be hosted on the same host machine, each topology name must be unique, otherwise we will run into conflicts.

Change the 'name' field from evpn-mpls to evpn-mpls-p1 for example using your preferred text editor (vi, nano, etc..)

Deploy the lab:
```
clab deploy --topo evpn-mpls.clab.yml
```

At the end of the deployment process, the following table will be displayed:

```
╭──────────────────────────┬────────────────────────────────────┬───────────┬────────────────────╮
│           Name           │             Kind/Image             │   State   │   IPv4/6 Address   │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-host1  │ linux                              │ running   │ 172.20.20.20       │
│                          │ ghcr.io/srl-labs/network-multitool │           │ 3fff:172:20:20::14 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-host2  │ linux                              │ running   │ 172.20.20.23       │
│                          │ ghcr.io/srl-labs/network-multitool │           │ 3fff:172:20:20::17 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-host3  │ linux                              │ running   │ 172.20.20.22       │
│                          │ ghcr.io/srl-labs/network-multitool │           │ 3fff:172:20:20::16 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-leaf1  │ nokia_sros                         │ running   │ 172.20.20.21       │
│                          │ vrnetlab/nokia_sros:24.10.R3       │ (healthy) │ 3fff:172:20:20::15 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-leaf2  │ nokia_sros                         │ running   │ 172.20.20.24       │
│                          │ vrnetlab/nokia_sros:24.10.R3       │ (healthy) │ 3fff:172:20:20::18 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-leaf3  │ nokia_sros                         │ running   │ 172.20.20.19       │
│                          │ vrnetlab/nokia_sros:24.10.R3       │ (healthy) │ 3fff:172:20:20::13 │
├──────────────────────────┼────────────────────────────────────┼───────────┼────────────────────┤
│ clab-evpn-mpls-p1-spine1 │ nokia_sros                         │ running   │ 172.20.20.18       │
│                          │ vrnetlab/nokia_sros:24.10.R3       │ (healthy) │ 3fff:172:20:20::12 │
╰──────────────────────────┴────────────────────────────────────┴───────────┴────────────────────╯
```

## Access

Login to any of the leaf or spine routers using ssh with username and password as admin.  For example:
```
ssh admin@clab-evpn-mpls-p1-leaf1
```

Interactively access the terminal of the linux hosts using 'docker exec -it'.  For example:

```
docker exec -it clab-evpn-mpls-p1-host1 /bin/bash
```

# Verify Current Setup

To get started with the lab, we will run various show commands to establish a baseline of connectivity.  Run these commands on each router in the topology.  The below example output is from Leaf1.

## Verify Routing

### OSPF 

show OSPF neighbors
```
A:admin@leaf1# show router ospf neighbor 

===============================================================================
Rtr Base OSPFv2 Instance 0 Neighbors
===============================================================================
Interface-Name                   Rtr Id          State      Pri  RetxQ   TTL
   Area-Id
-------------------------------------------------------------------------------
toSpine1                         10.101.1.1      Full       1    0       39
   0.0.0.0
-------------------------------------------------------------------------------
No. of Neighbors: 1
===============================================================================
```

### Route Table

show the route table and ensure that all system IPs are learned.

```
A:admin@leaf1# show router route-table 

===============================================================================
Route Table (Router: Base)
===============================================================================
Dest Prefix[Flags]                            Type    Proto     Age        Pref
      Next Hop[Interface Name]                                    Metric   
-------------------------------------------------------------------------------
1.1.1.1/32                                    Local   Local     00h11m14s  0
       system                                                       0
2.2.2.2/32                                    Remote  OSPF      00h10m29s  10
       10.1.1.0                                                     2
3.3.3.3/32                                    Remote  OSPF      00h10m29s  10
       10.1.1.0                                                     2
10.1.1.0/31                                   Local   Local     00h10m35s  0
       toSpine1                                                     0
10.1.2.0/31                                   Remote  OSPF      00h10m29s  10
       10.1.1.0                                                     2
10.1.3.0/31                                   Remote  OSPF      00h10m29s  10
       10.1.1.0                                                     2
10.101.1.1/32                                 Remote  OSPF      00h10m29s  10
       10.1.1.0                                                     1
-------------------------------------------------------------------------------
No. of Routes: 7
Flags: n = Number of times nexthop is repeated
       B = BGP backup route available
       L = LFA nexthop available
       S = Sticky ECMP requested
===============================================================================
```

## Verify MPLS

### RSVP Interfaces

List all rsvp interfaces

```
A:admin@leaf1# show router rsvp interface 

===============================================================================
RSVP Interfaces
===============================================================================
Interface                        Total    Active    Total BW  Resv BW   Adm Opr
                                 Sessions Sessions  (Mbps)    (Mbps)        
-------------------------------------------------------------------------------
system                           -        -         -         -         Up  Up
toSpine1                         2        2         10000     0         Up  Up
-------------------------------------------------------------------------------
Interfaces : 2
===============================================================================
```

### MPLS Interfaces

List all mpls interfaces

```
A:admin@leaf1# show router mpls interface 

===============================================================================
MPLS Interfaces
===============================================================================
Interface                           Port-id           Adm  Opr(V4/V6) TE-
                                                                      metric
-------------------------------------------------------------------------------
system                              system            Up   Up/Down    None
  Admin Groups                      None
  SRLG Groups                       None
toSpine1                            1/1/1             Up   Up/Down    None
  Admin Groups                      None
  SRLG Groups                       None
-------------------------------------------------------------------------------
Interfaces : 2
===============================================================================
```

### MPLS Tunnels and LSP paths

Router Tunnel Table: Take note that MPLS/RSVP is the tunnel type currently used.  Later in this lab, we will use this same command after we migrate to SR-OSPF.

```
A:admin@leaf1# show router tunnel-table 

===============================================================================
IPv4 Tunnel Table (Router: Base)
===============================================================================
Destination           Owner     Encap TunnelId  Pref   Nexthop        Metric
   Color                                                              
-------------------------------------------------------------------------------
2.2.2.2/32            sdp       MPLS  2         5      2.2.2.2        0
2.2.2.2/32            rsvp      MPLS  1         7      10.1.1.0       2
3.3.3.3/32            sdp       MPLS  3         5      3.3.3.3        0
3.3.3.3/32            rsvp      MPLS  2         7      10.1.1.0       2
-------------------------------------------------------------------------------
Flags: B = BGP or MPLS backup hop available
       L = Loop-Free Alternate (LFA) hop available
       E = Inactive best-external BGP route
       k = RIB-API or Forwarding Policy backup hop
===============================================================================
```
List all configured MPLS LSP Paths

```
A:admin@leaf1# show router mpls lsp

===============================================================================
MPLS LSPs (Originating)
===============================================================================
LSP Name                                            Tun     Fastfail  Adm  Opr
  To                                                Id      Config         
-------------------------------------------------------------------------------
to-Leaf2                                            1       Yes       Up   Up
  2.2.2.2                                                                  
to-Leaf3                                            2       Yes       Up   Up
  3.3.3.3                                                                  
-------------------------------------------------------------------------------
LSPs : 2
===============================================================================
```

LSP Path detail

```
show router mpls lsp path detail       


 ------------------------------SNIP--------------------------------------------
Explicit Hops    :                         
    No Hops Specified
Actual Hops      :                         
    10.1.1.1(1.1.1.1)                            Record Label        : N/A
 -> 10.1.1.0(10.101.1.1)                         Record Label        : 524287
 -> 10.1.2.1(2.2.2.2)                            Record Label        : 524286
Computed Hops    :                         
    10.1.1.1(S)       
 -> 10.1.1.0(S)       
 -> 10.1.2.1(S)       
Resignal Eligible: False                   
Last Resignal    : n/a                     CSPF Metric       : 2
```


## Verify Services

List configured SDPs

```
A:admin@leaf1# show service sdp

============================================================================
Services: Service Destination Points
============================================================================
SdpId  AdmMTU  OprMTU  Far End          Adm  Opr         Del     LSP   Sig
----------------------------------------------------------------------------
2      0       8682    2.2.2.2          Up   Up          MPLS    R     TLDP
3      0       8682    3.3.3.3          Up   Up          MPLS    R     TLDP
----------------------------------------------------------------------------
Number of SDPs : 2
----------------------------------------------------------------------------
Legend: R = RSVP, L = LDP, B = BGP, M = MPLS-TP, n/a = Not Applicable
        I = SR-ISIS, O = SR-OSPF, T = SR-TE, F = FPE
============================================================================
```

List configured services

```
A:admin@leaf1# show service service-using 

===============================================================================
Services 
===============================================================================
ServiceId    Type      Adm  Opr  CustomerId Service Name
-------------------------------------------------------------------------------
10           VPLS      Up   Up   1          vlan10
-------------------------------------------------------------------------------
Matching Services : 1
-------------------------------------------------------------------------------
===============================================================================
```

List configured SAPs

```
A:admin@leaf1# show service sap-using 

===============================================================================
Service Access Points 
===============================================================================
PortId                          SvcId      Ing.  Ing.          Egr.   Adm  Opr
                                           QoS   Fltr          Fltr        
-------------------------------------------------------------------------------
1/1/10:10                       10         1     none          none   Up   Up
-------------------------------------------------------------------------------
Number of SAPs : 1
-------------------------------------------------------------------------------
===============================================================================
```

List learned mac addresses per service.  Ensure that you have learned all 3 mac addresses for the linux hosts

```
A:admin@leaf1# show service id "10" fdb detail 

===============================================================================
Forwarding Database, Service 10
===============================================================================
ServId     MAC               Source-Identifier       Type     Last Change
            Transport:Tnl-Id                         Age      
-------------------------------------------------------------------------------
10         aa:c1:ab:60:8a:07 sdp:2:10                L/0      02/05/26 13:58:05
10         aa:c1:ab:62:b6:3d sdp:3:10                L/0      02/05/26 14:00:12
10         aa:c1:ab:9e:fa:e0 sap:1/1/10:10           L/0      02/05/26 13:57:45
-------------------------------------------------------------------------------
No. of MAC Entries: 3
-------------------------------------------------------------------------------
Legend:L=Learned O=Oam P=Protected-MAC C=Conditional S=Static Lf=Leaf T=Trusted
===============================================================================
```

# SR-MPLS

## Segment Routing Lable Range

In this example, we will configure the Segment Routing label ranges that each router will use to assign segment routing prefix SIDs.  This label range will be same on each router in the topology as part of the Segment Routing Global Block (SRGB).  Here we configure a static range as well so that the default ranges do not overlap with the configured SRGB. 
```
/configure router "Base" mpls-labels static-label-range 11968
/configure router "Base" mpls-labels sr-labels start 12000
/configure router "Base" mpls-labels sr-labels end 19999
```
## Segment Routing over OSPF - SR-OSPF

In this example we enable Segment Routing under the OSPF routing context.  The node SID index should be unique per node.  Leaf1 for example will use node-sid index 1, leaf2 will use node-side index 2, and so on.  See below:
Leaf1: 1
Leaf2: 2
Leaf3: 3
Spine1: 101

Leaf1 Example:
```
/configure router "Base" ospf 0 advertise-router-capability area
/configure router "Base" ospf 0 segment-routing admin-state enable
/configure router "Base" ospf 0 segment-routing prefix-sid-range global
/configure router "Base" ospf 0 area 0.0.0.0 interface "system" node-sid index 1
```

### Show commands for validation of SR SID propogation and SR tunnels

```
show router ospf opaque-database
```

#### Opaque Database LSA Types

Type 1 = Traffic LSA\
Type 4 = Router Information LSA\
Type 7 = Extended Prefix LSA\
Type 8 = Extended Link LSA

```
show router ospf opaque-database adv-router x.x.x.x ls-id x detail 
```

Display the router tunnel table to show both SR and RSVP tunnels:
```
 show router tunnel-table 
```

This tools command will provide absolute label id for each tunnel:
```
tools dump router segment-routing tunnel
```

# EVPN-MPLS

## BGP

Configure BGP to exchange EVPN routes.  We will setup a iBGP peering session between all Leaf1 and Leaf2 only because as mentioned in the toplogy session, only Leaf1 and Leaf2 will be configured with over VPLS over EVPN-MPLS.

Leaf1 example peering to the system IP of Leaf2:
```
/configure router autonomous-system 65001
/configure router "Base" bgp min-route-advertisement 1
/configure router "Base" bgp vpn-apply-export true
/configure router "Base" bgp vpn-apply-import true
/configure router "Base" bgp rapid-withdrawal true
/configure router "Base" bgp peer-ip-tracking true
/configure router "Base" bgp rapid-update vpn-ipv4 true
/configure router "Base" bgp rapid-update evpn true
/configure router "Base" bgp group "evpn" type internal
/configure router "Base" bgp group "evpn" family evpn true
/configure router "Base" bgp neighbor "2.2.2.2" group "evpn"
```

## Migrate to spoke-sdp
On Leaf1 and Leaf2 migrate to spoke SDP in order to add the EVPN configuration.  We will also create a Split Horizon group which we will add both the spokes and EVPN tunnels to.

Example on Leaf1:
```
/configure service vpls "vlan10" delete mesh-sdp 2:10 
/configure service vpls "vlan10" delete mesh-sdp 3:10 
/configure service vpls "vlan10" spoke-sdp 2:10 admin-state enable
/configure service vpls "vlan10" spoke-sdp 3:10 admin-state enable
/configure service { vpls "vlan10" split-horizon-group "shg-10" }
/configure service vpls "vlan10" spoke-sdp 2:10 split-horizon-group "shg-10"
/configure service vpls "vlan10" spoke-sdp 3:10 split-horizon-group "shg-10"
```

## EVPN

In this section will add add the necessary bgp-evpn configuration options
Example on Leaf1:
```
/configure service vpls "vlan10" proxy-arp admin-state enable
/configure service vpls "vlan10" proxy-arp dynamic-populate true
/configure service vpls "vlan10" bgp 1 route-distinguisher "1.1.1.1:10"
/configure service vpls "vlan10" bgp 1 route-target export "target:65001:10"
/configure service vpls "vlan10" bgp 1 route-target import "target:65001:10"
/configure service vpls "vlan10" bgp-evpn evi 10
/configure service vpls "vlan10" bgp-evpn mpls 1 admin-state enable
/configure service vpls "vlan10" bgp-evpn mpls 1 split-horizon-group "shg-10"
/configure service vpls "vlan10" bgp-evpn mpls 1 ecmp 2
/configure service vpls "vlan10" bgp-evpn mpls 1 auto-bind-tunnel resolution any
```


### show commands

EVPN Route verification:
```
show router bgp neighbor "<neighbor-ip>" advertised-routes evpn incl-mcast 
show router bgp neighbor "<neighbor-ip>" advertised-routes evpn mac 
show router bgp neighbor "<neighbor-ip>" received-routes evpn 
show router bgp neighbor "<neighbor-ip>" advertised-routes evpn 
```

Verify proxy arp:
```
show service id 10 proxy-arp detail 
```

With the completion of this section you should see EVPN routes exchanged between Leaf1 and Leaf2, however the remote MACs will still be preferred over the existing spoke SDPs.  
Let's change that by migrating the VPLS services over to SR-OSPF.

# SR-MPLS Migration

Here we will showcase two different options for migrating to SR-OSPF.

## Option 1: Change tunnel preference on a per service basis

This will only affect specific services that we configure to prefer SR-OSPF over RSVP-TE.

Enter the following command on both Leaf1 and Leaf2
```
/configure service vpls "vlan10" bgp-evpn mpls 1 auto-bind-tunnel resolution-filter sr-ospf true
```

Verify where the remote MACs are learned from in the FDB table
```
show service id 10 fdb detail 
```

Once we have verified that our tunnels work over SR-OSPF lets revert back to resolution 'any' to demonstrate the second option.
```
/configure service vpls "vlan10" bgp-evpn mpls 1 auto-bind-tunnel resolution-filter delete rsvp
/configure service vpls "vlan10" bgp-evpn mpls 1 auto-bind-tunnel resolution any 
```

## Option 2: Change tunnel preference system wide

Now that we have confirmed SR-OSPF is working, let's make a system wide change and convert all 3 leaf routers to use SR-OSPF tunnels.  **RSVP is given a higher preference value so that OSPF is preferred in our topology.**

Here we will raise the tunnel table preference for RSVP.  Now SR-OSPF, when avaiable, will be the preferred tunnel for all services.
```
/configure router "Base" mpls tunnel-table-pref rsvp-te 15
```

Verify the FDB table.  Leaf1 and Leaf2 should now learn the remote MACs from each other over EVPN-MPLS.
```
show service id 10 fdb detail 
```

### Convert to SR-OSPF

Here, we will convert all spoke SDPs connected to Leaf3 to SR-OSPF and remove the spoke SDPs between Leaf1 and Leaf2, as EVPN-MPLS is now preferred.

Example on Leaf1:
```
/configure service vpls "vlan10" delete spoke-sdp 2:10 
/configure service delete sdp 2
/configure service sdp 3 delete lsp "to-Leaf3" 
/configure service sdp 3 sr-ospf true 
```

Example on Leaf2:
```
/configure service vpls "vlan10" delete spoke-sdp 1:10 
/configure service delete sdp 1
/configure service sdp 3 delete lsp "to-Leaf3" 
/configure service sdp 3 sr-ospf true 
```

Example on Leaf3:
```
/configure service sdp 1 delete lsp "to-Leaf1" 
/configure service sdp 1 sr-ospf true
/configure service sdp 2 delete lsp "to-Leaf2" 
/configure service sdp 2 sr-ospf true
```

Verify SR-OSFP is enabled on the SDP:
```
show service  sdp 1 detail 
 
 ------------------------------SNIP--------------------------------------------
-------------------------------------------------------------------------------
Segment Routing
-------------------------------------------------------------------------------
ISIS                 : disabled              
OSPF                 : enabled               LSP Id             : 524290
Oper Instance Id     : 0                     
TE-LSP               : disabled              
===============================================================================
```

RSVP is no longer preferred.

Now let's take a big leap and remove mpls and rsvp completely from all routers!!

Run the below commands on Leaf1, Leaf2, Leaf3 and Spine1:
```
/configure router delete rsvp 
/configure router delete mpls
```

Verify that SR-OSPF tunnels are used int the tunnel table:
```
show router tunnel-table 
```

Verify all MACs are still in the fdb table:
```
show service id 10 fdb detail 
```

Congratulations, you have fully migrated a network from RSVP to SR-OSPF

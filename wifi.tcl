# Define simulation parameters
set val(chan) Channel/WirelessChannel ;# Channel Type
set val(prop) Propagation/TwoRayGround ;# Propagation model
set val(netif) Phy/WirelessPhy ;# PHY layer
set val(mac) Mac/802_11 ;# MAC layer
set val(ifq) Queue/DropTail/PriQueue ;# Queue type
set val(ll) LL ;# Link layer
set val(ant) Antenna/OmniAntenna ;# Antenna type
set val(ifqlen) 50 ;# Queue length
set val(nn) 10 ;# Number of nodes
set val(rp) DumbAgent ;# Routing protocol
set val(x) 600 ;# Area width
set val(y) 600 ;# Area height

# Initialize the simulator
set ns_ [new Simulator]
set tracefd [open project1.tr w]
$ns_ trace-all $tracefd
set namtrace [open project1.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# Set up the topography
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Create the 'God' (God object for node positioning)
create-god $val(nn)

# Create and configure the channel
set chan_1_ [new $val(chan)]
$ns_ node-config -adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
-topoInstance $topo \
-agentTrace OFF \
-routerTrace OFF \
-macTrace ON \
-movementTrace ON \
-channel $chan_1_

# Create nodes and configure their properties
for {set i 0} {$i < $val(nn)} {incr i} {
    set node_($i) [$ns_ node]
    $node_($i) random-motion 0
    set mac_($i) [$node_($i) getMac 0]
    $mac_($i) set RTSThreshold_ 3000
}

# Set initial positions and labels for nodes
set positions {
    {200.0 360.0} {100.0 100.0} {400.0 400.0} {280.0 140.0}
    {100.0 320.0} {70.0 210.0} {440.0 310.0} {490.0 320.0}
    {520.0 280.0} {560.0 360.0}
}
set labels {AP1 N1 MN1 MN2 MN3 MN4 MN5 MN6 MN7 AP2}

set colors {green red yellow blue purple pink orange cyan brown grey}
for {set i 0} {$i < $val(nn)} {incr i} {
    # Set position and label
    set pos [lindex $positions $i]
    $node_($i) set X_ [lindex $pos 0]
    $node_($i) set Y_ [lindex $pos 1]
    $node_($i) set Z_ 0.0
    $ns_ at 0.0 "$node_($i) label [lindex $labels $i]"
    
    # Set color mark
    set color [lindex $colors $i]
    $ns_ at 0.0 "$node_($i) add-mark m1 $color circle"
}

# Configure the access points (APs)
set AP_ADDR1 [$mac_(0) id]
$mac_(0) ap $AP_ADDR1
set AP_ADDR2 [$mac_([expr $val(nn) - 1]) id]
$mac_([expr $val(nn) - 1]) ap $AP_ADDR2

# Set scan types for nodes
$mac_(1) ScanType ACTIVE
for {set i 3} {$i < [expr $val(nn) - 1]} {incr i} {
    $mac_($i) ScanType PASSIVE
}
$ns_ at 1.0 "$mac_(2) ScanType ACTIVE"

# Set up CBR traffic and UDP agents
Application/Traffic/CBR set packetSize_ 1023
Application/Traffic/CBR set rate_ 256Kb
for {set i 1} {$i < [expr $val(nn) - 1]} {incr i} {
    set udp1($i) [new Agent/UDP]
    $ns_ attach-agent $node_($i) $udp1($i)
    set cbr1($i) [new Application/Traffic/CBR]
    $cbr1($i) attach-agent $udp1($i)
}

# Attach Null agents and configure connections
set nulls [list]
for {set i 0} {$i < 7} {incr i} {
    lappend nulls [new Agent/Null]
}
for {set i 2} {$i < 9} {incr i} {
    $ns_ attach-agent $node_(1) [lindex $nulls [expr $i - 2]]
    $ns_ connect $udp1($i) [lindex $nulls [expr $i - 2]]
}

# Set initial node positions and movement
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ initial_node_pos $node_($i) 30
}
$ns_ at 8.0 "$cbr1(2) start"
$ns_ at 2.0 "$cbr1(3) start"
$ns_ at 3.0 "$cbr1(4) start"
$ns_ at 4.0 "$cbr1(5) start"
$ns_ at 5.0 "$cbr1(6) start"
$ns_ at 6.0 "$cbr1(7) start"
$ns_ at 7.0 "$cbr1(8) start"

# Define node movements
$ns_ at 10.0 "$node_(4) setdest 590.0 350.0 1000.0"
$ns_ at 35.0 "$node_(5) setdest 460.0 360.0 1000.0"
$ns_ at 50.0 "$node_(3) setdest 590.0 350.0 1000.0"
$ns_ at 52.0 "$node_(3) setdest 100.0 360.0 1000.0"

# End the simulation
$ns_ at 100.0 "stop"
$ns_ at 100.0 "puts \"NS EXITING...\" ; $ns_ halt"

proc stop {} {
    global ns_ tracefd
    $ns_ flush-trace
    close $tracefd
    exec nam project1.nam
    exit 0
}

puts "Starting Simulation..."
$ns_ run
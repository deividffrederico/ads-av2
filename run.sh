#!/bin/bash

TOPOLOGY_FILE=scenario.imn
BANDWIDTH=100000000
# SCENARIO_ID=i2002
# DELAY=10000
# FLUXES=1

# Create a log directory if it doesn't exist
mkdir -p ./log

echo "========================================================="
echo "Starting IMUNES simulation with scenario ID: $SCENARIO_ID"

# Run IMUNES in background and redirect all output to log
sudo imunes -b -e $SCENARIO_ID $TOPOLOGY_FILE > /dev/null
sleep 2

echo "========================================================="
echo "Simulation started, applying commands..."

# Link configurations
sudo vlink -bw $BANDWIDTH -dly $DELAY router1:pc1@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router1:pc3@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:pc2@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:pc4@$SCENARIO_ID > /dev/null
sudo vlink -bw $BANDWIDTH -dly $DELAY router2:router1@$SCENARIO_ID > /dev/null
sleep 2

# Check status (optional)
sudo vlink -s router1:pc1@$SCENARIO_ID
sudo vlink -s router1:pc3@$SCENARIO_ID
sudo vlink -s router2:pc2@$SCENARIO_ID
sudo vlink -s router2:pc4@$SCENARIO_ID
sudo vlink -s router2:router1@$SCENARIO_ID
sleep 2

# Start iperf servers
sudo himage pc2@$SCENARIO_ID iperf -s &> /dev/null &
sudo himage pc4@$SCENARIO_ID iperf -s &> /dev/null &

# Generate background UDP traffic (mute output)
sudo himage pc1@$SCENARIO_ID iperf -c 10.0.3.20 -u -t 100000 -b 10M &> /dev/null &
sleep 2


# Run TCP test (this is the one you want to see)
echo "========================================================="
echo "Running TCP test between PC3 and PC4..."
sudo himage pc3@$SCENARIO_ID iperf -c 10.0.4.20 -n 100M -P $FLUXES -i 1 

# Stop simulation
echo "========================================================="
echo "Stopping IMUNES simulation with scenario ID: $SCENARIO_ID"
sudo imunes -b -e $SCENARIO_ID > /dev/null
echo "========================================================="
echo "Simulation stopped"




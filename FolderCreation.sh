#!/bin/bash

# Create the main directory
sudo mkdir -p /EmployeeData/{HR,IT,Finance,Admin}

# Set secure permissions: 
# Owner can read/write/execute, others have no access (700)
sudo chmod 700 /EmployeeData
sudo chmod 700 /EmployeeData/HR
sudo chmod 700 /EmployeeData/IT
sudo chmod 700 /EmployeeData/Finance
sudo chmod 700 /EmployeeData/Admin

# Optional: Set ownership to root (can be modified based on your needs)
sudo chown root:root /EmployeeData
sudo chown root:root /EmployeeData/HR
sudo chown root:root /EmployeeData/IT
sudo chown root:root /EmployeeData/Finance
sudo chown root:root /EmployeeData/Admin

echo "Secure folder structure created successfully under /EmployeeData."

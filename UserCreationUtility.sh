#!/bin/bash

# Ensure an input file is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Verify that the input file exists
if [[ ! -f "$1" ]]; then
    echo "Error: File '$1' not found."
    exit 1
fi

new_users=0
new_groups=0

# Read each line from the file, using ',' as the delimiter
while IFS=',' read -r firstname lastname department; do
    # Generate username (first letter of firstname + up to 7 letters of lastname, lowercase)
    username="$(echo "${firstname:0:1}${lastname:0:7}" | tr '[:upper:]' '[:lower:]')"
    
    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists, skipping."
    else
        sudo useradd -m -s /bin/bash "$username"
        echo "Created user '$username'."
        ((new_users++))
    fi
    
    # Check if the group exists, create if necessary
    if ! getent group "$department" &>/dev/null; then
        sudo groupadd "$department"
        echo "Created group '$department'."
        ((new_groups++))
    fi
    
    # Add user to the department group
    sudo usermod -aG "$department" "$username"
    echo "Added '$username' to group '$department'."

done < "$1"

echo "Operation completed: $new_users users created, $new_groups groups created."

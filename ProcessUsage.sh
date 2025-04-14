#!/bin/bash
# Utility to monitor and stop high CPU usage tasks (excluding root user and critical processes)
# Programmed by: Jeremiah
# Written on: March 08, 2025

# Set the current date for the report naming
CURRENT_DATE=$(date +%Y%m%d)

# Define the report file and output log directly in the home directory
REPORT_NAME="$HOME/ProcessUsageReport_${CURRENT_DATE}"
OUTPUT_LOG="$HOME/ProcessUsageOutput_${CURRENT_DATE}"

# Ensure the home directory is writable
if [ ! -w "$HOME" ]; then
    echo "Error: Home directory $HOME is not writable. Please check permissions."
    exit 1
fi

# Step 1: Locate the top 5 processes consuming the most CPU, excluding root and the ps command itself
echo "Identifying the top 5 CPU-intensive tasks..." | tee -a "$OUTPUT_LOG"
top_processes=$(ps -eo user,pid,%cpu,cmd --sort=-%cpu | grep -v "root" | grep -v "ps -eo" | head -n 6 | tail -n 5)

# Check if there are any tasks to terminate
if [ -z "$top_processes" ]; then
    echo "No tasks found that can be terminated (excluding root)." | tee -a "$OUTPUT_LOG"
    exit 0
fi

# Step 2: Show the user the top processes and ask for permission to proceed
echo "These tasks are using the most CPU resources:" | tee -a "$OUTPUT_LOG"
echo "$top_processes" | tee -a "$OUTPUT_LOG"
read -p "Would you like to terminate these tasks? (yes/no): " user_permission
if [ "$user_permission" != "yes" ]; then
    echo "User chose to cancel the termination process." | tee -a "$OUTPUT_LOG"
    exit 0
fi

# Step 3: Terminate the tasks and save details to the report with error handling and retries
echo "Starting the termination and logging procedure..." | tee -a "$OUTPUT_LOG"
echo "=== CPU Usage Termination Report by Jeremiah - $CURRENT_DATE ===" > "$REPORT_NAME" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: Could not create report file at $REPORT_NAME. Check disk space and permissions." | tee -a "$OUTPUT_LOG"
    exit 1
fi
echo "$top_processes" >> "$REPORT_NAME"
TERMINATED_COUNT=0
ATTEMPTED_COUNT=0

while read -r account task_id cpu_load task_cmd; do
    if [ -n "$task_id" ] && [ "$account" != "root" ]; then
        ((ATTEMPTED_COUNT++))
        # Skip critical processes like gnome-shell to prevent session crashes
        if [[ "$task_cmd" == *"gnome-shell"* ]]; then
            echo "Skipped Task ID: $task_id (Command: $task_cmd) - Critical process avoided" >> "$REPORT_NAME"
            echo "-----------------------------" >> "$REPORT_NAME"
            continue
        fi
        # Attempt to terminate the process with retries
        for i in {1..3}; do
            kill -9 "$task_id" 2>/dev/null && break
            sleep 0.1
        done
        if [ $? -eq 0 ]; then
            echo "a. Account Name: $account" >> "$REPORT_NAME"
            echo "b. Task ID: $task_id" >> "$REPORT_NAME"
            echo "c. Initiated At: $(ps -p $task_id -o lstart --no-headers 2>/dev/null || echo 'Unknown')" >> "$REPORT_NAME"
            echo "d. Terminated At: $(date)" >> "$REPORT_NAME"
            echo "e. Group: $(id -gn $account 2>/dev/null || echo 'Unknown')" >> "$REPORT_NAME"
            echo "-----------------------------" >> "$REPORT_NAME"
            ((TERMINATED_COUNT++))
        else
            echo "Failed to terminate Task ID: $task_id (Command: $task_cmd)" >> "$REPORT_NAME"
            echo "a. Account Name: $account" >> "$REPORT_NAME"
            echo "b. Task ID: $task_id" >> "$REPORT_NAME"
            echo "c. Initiated At: $(ps -p $task_id -o lstart --no-headers 2>/dev/null || echo 'Unknown')" >> "$REPORT_NAME"
            echo "d. Termination Attempted At: $(date)" >> "$REPORT_NAME"
            echo "e. Group: $(id -gn $account 2>/dev/null || echo 'Unknown')" >> "$REPORT_NAME"
            echo "-----------------------------" >> "$REPORT_NAME"
        fi
    fi
done <<< "$top_processes"

# Step 5: Provide a final summary message
echo "=== Termination Report ===" | tee -a "$OUTPUT_LOG"
echo "Termination of tasks has been completed." | tee -a "$OUTPUT_LOG"
echo "Total tasks attempted: $ATTEMPTED_COUNT" | tee -a "$OUTPUT_LOG"
echo "Total tasks successfully terminated: $TERMINATED_COUNT" | tee -a "$OUTPUT_LOG"
echo "Report saved as: $REPORT_NAME" | tee -a "$OUTPUT_LOG"
echo "========================" | tee -a "$OUTPUT_LOG"

# Verify the report file exists
if [ ! -f "$REPORT_NAME" ]; then
    echo "Error: Report file $REPORT_NAME was not created." | tee -a "$OUTPUT_LOG" >&2
    exit 1
else
    # Ensure file permissions allow reading
    chmod u+r "$REPORT_NAME" 2>/dev/null
fi

exit 0

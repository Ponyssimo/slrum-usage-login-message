# slurm-usage-login-message

Scripts to generate login message reporting resource utilization for RIT's SPORC cluster

Usage: Place all three scripts in a single directory, and set up a chron job to run generate-message-chron.sh at the desired time interval. Add a line to `/etc/profile` to run print-message.sh when a user logs in.
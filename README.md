# F5-WideIP-Offline-Export

####Create script
cat << 'EOF' > generate_wideip_report.sh

CPU Impact Considerations

With 300+ Wide IPs, this script will be more CPU intensive than if tmsh list gtm wideip full were supported. Each iteration of the while loop will:

    Spawn a new tmsh show process.

    Pipe its output through sed, tr, sed again, grep, and awk.

This chain of command execution for each Wide IP (300+ times) is where the CPU overhead comes from.

Recommendations for production environment with many Wide IPs:

    Schedule During Off-Peak Hours: If possible, run this script during times when your F5 BIG-IP system is under lower load.

    Monitor Performance: Keep an eye on the F5's CPU and memory usage when the script is running for the first time with a large number of Wide IPs.

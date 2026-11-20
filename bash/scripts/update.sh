#!/bin/bash

echo "======================================"
echo "   Pop!_OS System Update Script"
echo "======================================"
echo ""

# Update APT packages
echo "📦 Updating APT repositories and packages..."
sudo apt update && sudo apt full-upgrade -y

# Clean up unnecessary packages
echo ""
echo "🧹 Cleaning up old packages..."
sudo apt autoremove -y
sudo apt autoclean

# Update Flatpak applications
echo ""
echo "📱 Updating Flatpak applications..."
flatpak update -y

# Optional: Try to update recovery partition (safe to fail)
echo ""
echo "🔄 Updating recovery partition (if available)..."
pop-upgrade recovery upgrade from-release || echo "   (Recovery update skipped - normal on some systems)"

echo ""
echo "✅ Update process completed!"
echo ""
echo "💡 Recommendation: Reboot your system now if kernel or graphics drivers were updated."
read -p "Would you like to reboot now? (y/N): " reboot_choice

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    echo "Remember to reboot later for best results."
fi
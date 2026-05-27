#!/usr/bin/env bash
set -eu

echo "Restoring system preferences..."

###############################################################################
# Prepare to apply changes                                                    #
###############################################################################

# Ask for sudo once, keep-alive
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# Close any open System Settings panes, to prevent them from overriding
# settings we're about to change
osascript -e 'tell application "System Settings" to quit'

###############################################################################
# Computer and network                                                        #
###############################################################################

# Prompt for computer name
read -p "Enter your computer name (e.g., John's MacBook): " COMPUTER_NAME

# Generate hostname-friendly version (remove spaces, apostrophes, and special characters)
LOCAL_HOST_NAME=$(echo "$COMPUTER_NAME" | sed "s/'//g" | sed 's/ /-/g')

# Set computer name
sudo scutil --set ComputerName "$COMPUTER_NAME"
sudo scutil --set HostName "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$LOCAL_HOST_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

###############################################################################
# UI/UX                                                                       #
###############################################################################

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

###############################################################################
# Screenshots                                                                 #
###############################################################################

# Save screenshots to the downloads folder
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Languages and region                                                        #
###############################################################################

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Set language and text formats
defaults write NSGlobalDomain AppleLanguages -array "en-US" "th-TH"
defaults write NSGlobalDomain AppleLocale -string "en_GB@calendar=gregorian;rg=thzzzz"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Trackpad: enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Trackpad: tracking speed (fastest)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3.0

###############################################################################
# Menu bar                                                                    #
###############################################################################
# Show seconds in menu bar digital clock
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm:ss"
defaults write com.apple.menuextra.clock Show24Hour -int 1
defaults write com.apple.menuextra.clock ShowSeconds -int 1

###############################################################################
# Dock                                                                        #
###############################################################################

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0
# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Set apps in Dock
defaults write com.apple.dock persistent-apps -array

for app in \
  "/System/Applications/Apps" \
  "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari" \
  "/Applications/Google Chrome" \
  "/Applications/LINE" \
  "/Applications/WhatsApp" \
  "/Applications/Slack" \
  "/Applications/Microsoft Teams" \
  "/System/Applications/FaceTime" \
  "/Applications/Claude" \
  "/Applications/iTerm" \
  "/Applications/Visual Studio Code" \
  "/System/Applications/App Store" \
  "/System/Applications/iPhone Mirroring" \
  "/System/Applications/System Settings"; do
  app_string="
  <dict>
    <key>tile-data</key>
    <dict>
      <key>file-data</key>
      <dict>
        <key>_CFURLString</key>
        <string>${app}.app</string>
        <key>_CFURLStringType</key>
        <integer>0</integer>
      </dict>
    </dict>
  </dict>
  "
  defaults write com.apple.dock persistent-apps -array-add "$app_string"
done

# Set folders in Dock
defaults write com.apple.dock persistent-others -array

for other in \
  "${HOME}/Downloads/"; do
  other_string="
  <dict>
    <key>tile-data</key>
    <dict>
      <key>displayas</key>
      <integer>0</integer>
      <key>file-data</key>
      <dict>
        <key>_CFURLString</key>
        <string>file://${other}</string>
        <key>_CFURLStringType</key>
        <integer>15</integer>
      </dict>
      <key>file-type</key>
      <integer>2</integer>
      <key>showas</key>
      <integer>0</integer>
    </dict>
    <key>tile-type</key>
    <string>directory-tile</string>
  </dict>
  "
  defaults write com.apple.dock persistent-others -array-add "$other_string"
done

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Don’t display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

###############################################################################
# Time Machine                                                                #
###############################################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Google Chrome                                                               #
###############################################################################

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Kill affected applications                                                  #
###############################################################################

echo "System preferences restored"

# Kill affected applications (only when running as main script, not when sourced)
if [ "$0" = "$BASH_SOURCE" ]; then
  for app in \
    "SystemUIServer" \
    "Dock" \
    "Finder" \
    "Photos" \
    "Google Chrome"; do
    killall "${app}" &>/dev/null
  done
fi
#flatpak install flathub org.gnome.dspy
#sudo apt install -y d-feet

#---------------------------------------------------------------------------------------
# Install PipeWire so you can get audio and use the mic on a BT headset:
#
#   "PipeWire is the modern replacement for PulseAudio and supports using Bluetooth headsets
#    with both mic + audio at once — properly."

# From: https://gist.github.com/the-spyke/2de98b22ff4f978ebf0650c90e82027e
#
# Starting from WirePlumber version 0.4.8 automatic Bluetooth profile switching
# (e.g. switching from A2DP to HSP/HFP when an application needs microphone access) is supported.
# Jammy (22.04) repos provide exactly version 0.4.8. So, we're good.
#---------------------------------------------------------------------------------------
pipewire() {
  # 1. Install PipeWire & bluetooth modules
  #    - use wireplumber as session manager instead of pipewire session manager
  sudo apt install -y \
    pipewire \
    pipewire-audio-client-libraries \
    pipewire-pulse \
    wireplumber \
    pipewire-media-session-

  # Install the codecs and remove Bluetooth from PulseAudio, so it would be handled directly by PipeWire:
  sudo apt install -y \
    libldacbt-abr2 \
    libldacbt-enc2 \
    libspa-0.2-bluetooth \
    pulseaudio-module-bluetooth-

  # 2. Disable PulseAudio
  sudo apt remove pulseaudio-module-bluetooth
  systemctl --user --now disable pulseaudio.service pulseaudio.socket
  systemctl --user mask pulseaudio

  # 3. Enable pipewire
  systemctl --user --now enable pipewire pipewire-pulse

  # 4. Enable wireplumber
  systemctl --user --now enable wireplumber

  # 5. Reboot (only 1st time these are all installed - and maybe not even then)
  #sudo shutdown -r now
}

helvum() {
  #---------------------------------------------------------------------------------------
  # Install 'helvum' (PulseAudio Volume Control for PipeWire)
  #---------------------------------------------------------------------------------------
  # 1. Install Flatpak (if not already)
  sudo apt install flatpak

  # 2. Enable Flathub (if not already)
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  # 3. Install Helvum
  flatpak install flathub org.pipewire.Helvum

  # 4. Run Helvum
  #flatpak run org.pipewire.Helvum

}

pulseaudioVolumeControl() {
  # Install PulseAudio volume control GUI (nice b/c can get to it from Synapse)
  sudo apt install pavucontrol
}

# This supposedly turns off microphone volume from auto-adjusting - not sure if
# it actually is needed or not
# From: https://www.linux.org/threads/prevent-applications-from-changing-microphone-gain.41636/
setupWireplumberConfig() {
  # symlink ~/.config/wireplumber/ from ~/.personal/.config/wireplumber
  # Run: systemctl --user restart wireplumber pipewire pipewire-pulse
}

pipewire

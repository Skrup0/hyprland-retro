1. Build the patched hyprbars:

   ```sh
   git clone https://github.com/hyprwm/hyprland-plugins ~/Documents/hyprland-plugins
   cd ~/Documents/hyprland-plugins
   git apply hyprbars-retro.patch
   make -C hyprbars
   ```

2. Install imgborders:

   ```sh
   hyprpm add https://github.com/zacoons/imgborders
   hyprpm enable imgborders
   ```

3. Start Emacs once so it installs its packages, tho keep in mind that if it is built with native compilation then it will do that in the background which is normal behavior.

4. Org notes go in `~/Documents/notes` for the study bar.

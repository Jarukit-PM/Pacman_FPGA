# Pacman_FPGA

Pacman_FPGA is a complete Pac-Man–style hardware game built in Verilog for Xilinx Artix-7 FPGA boards with VGA output (tested on Digilent Basys 3). The design renders a 640×480@60 Hz scene, animates Pac-Man, two ghosts, score collectibles, and heart-based lives, and exposes push-button controls plus a 4-digit seven-segment score interface. Everything needed to rebuild the bitstream in Vivado is included in the `Pacman` project directory.

## Features
- 640×480 VGA pipeline with background ROM, walls, animated sprites, and a layered compositor.
- Pac-Man finite-state motion controller with wall avoidance, facing-dependent sprites, and post-hit ghost animation.
- Two autonomous ghosts with independent speed controls, plus collision detection against Pac-Man.
- Collectible stars that respawn across eight maze regions and drive a 4-digit score counter.
- Heart/life management, invincibility window, and game state machine (start → play → hit → game over) with restart logic.
- Optional seven-segment score display interface (`sseg`, `an`) alongside the VGA overlay.
- Ready-to-use bitstream (`Pacman/Pacman.runs/impl_1/top_module.bit`) generated with Vivado 2015.4.

## Repository Layout
- `Pacman/` – Vivado project (`Pacman.xpr`), HDL sources under `Pacman.srcs/sources_1/new/`, synthesis/implementation runs, and generated bitstream.
- `Finish/` – Demo video plus the original project presentation and report for reference.
- Image assets (`*.png`, `*.psd`, `*.avif`, audio) – source artwork used to build the sprite and background ROMs.
- `README.md` – This guide.

## Requirements
### Hardware
- Xilinx Artix-7 FPGA board with: 100 MHz system clock, 4 directional push buttons, at least one extra push button for `start_btn`, synchronous reset (`Phycal_rst`), VGA output, and a 4-digit seven-segment display (e.g., Digilent Basys 3 or Nexys A7 with minor pin map edits).
- VGA monitor capable of 640×480@60 Hz and cable.

### Software
- Vivado Design Suite 2015.4 (matches the provided run artifacts). Newer Vivado versions typically work but may trigger IP upgrade prompts.
- Optional: Active-HDL/ModelSim/etc. if you plan to run simulations (netlists are generated automatically by Vivado).

## Quick Start
1. **Clone / copy** the repo to your workstation:  
   `git clone https://github.com/<you>/Pacman_FPGA.git`
2. **Launch Vivado 2015.4** → *File → Open Project* → select `Pacman/Pacman.xpr`.
3. **Review constraints:** provide or update an `.xdc` matching your board pinout (buttons, VGA, seven-seg). The original project used the Basys 3 reference constraint file; use it as a template.
4. **Run synthesis & implementation** (`Flow → Run Implementation`). The shipped `top_module.bit` can be reused if no edits were made.
5. **Program the FPGA** via *Open Hardware Manager* → *Program Device* → select `top_module.bit`.

## Controls & Gameplay
- `btnL/btnR/btnU/btnD` – steer Pac-Man; movement speed accelerates while a button remains pressed.
- `start_btn` – transition from the attract/start state into active play and reset the game after Game Over.
- `Phycal_rst` – global reset (maps well to the board’s dedicated reset button).
- 4-digit `sseg/an` – optional score display (enable `Score_display` in `top_module.v` if you want a hardware seven-seg output).
- VGA scene layers in priority order: walls, Pac-Man, ghosts, hearts, stars, game-over banner, background.

Gameplay flow:
1. Power on/reset → start screen with idle sprites.
2. Press `start_btn` → game enables, hearts reset to three, Pac-Man becomes controllable.
3. Collide with ghosts → lose one heart; temporary invulnerability (~2 s) is enforced in the `hit` state.
4. Collect stars to gain 10 points each. After the final heart is lost the design shows the game-over banner until `start_btn` is tapped again.

## HDL Architecture Overview
- `top_module.v` – Top-level wiring of VGA sync, sprite engines, score logic, and game state machine. Sets sprite draw priority and exposes board I/O.  
  ```1:155:Pacman/Pacman.srcs/sources_1/new/top_module.v
  vga_sync vsync_unit(...);
  Background_rom Background_unit(...);
  Walls Walls_unit(...);
  Pacman_control Pacman_unit(...);
  Ghost_blue Ghost_blue_unit(...);
  Ghost_red Ghost_red_unit(...);
  Stars Stars_unit(...);
  ```
- `vga_sync.v` – Generates the 25 MHz pixel tick, HS/VS pulses, and 10-bit x/y counters for 640×480 timing.
- `Pacman_control.v` – Handles motion FSM, wall detection, direction register, sprite ROM selection, and collision animation.  
  ```15:360:Pacman/Pacman.srcs/sources_1/new/Pacman_control.v
  Pacman_rom Pacman_rom_unit(...);
  Pacman_Ghost_rom Pacman_ghost_rom_unit(...);
  ...
  if(pacman_area && video_on) begin
      rgb_out = collision_time_reg > 0 ? color_data_pacman_ghost : color_data_pacman;
  end
  ```
- `Ghost_blue.v` & `Ghost_red.v` – Parameterized chaser FSMs with independent `speed_offset` values (tune difficulty in `top_module`).
- `Game_state_machine.v` – Four-state FSM managing hearts, enable gating, collision timers, and restart behavior.
- `Stars.v` – Respawns collectibles across predefined maze regions, tracks score, and raises `new_score` pulses for optional seven-seg output.
- `Check_collision.v`, `Hearts_display.v`, `gameover_display.v`, `Walls.v`, and the various `*_rom.v` files contain collision math and ROM-based sprite data for each visual element.

## Customizing & Regenerating Assets
- Each sprite/background is encoded by a dedicated ROM (e.g., `Pacman_rom.v`, `Background_rom.v`). The ROM contents were derived from the PNG assets in the repository.
- To swap artwork, regenerate the hex initialization for the ROMs (common approaches: Python script → `$readmemh`, or Vivado’s IP catalog ROM generator).
- Update the `Walls` and `check_wall()` logic in `Pacman_control.v` if you redesign the maze layout.
- Adjust ghost behavior by editing their FSMs or the `speed_offset_*` constants in `top_module.v`.

## Simulation & Debug Tips
- Use Vivado’s behavioral simulation to verify timing-sensitive modules (`vga_sync`, FSMs). Sim sets are already configured inside the project (`Pacman.sim/`).
- The project currently hard-wires the pixel clock to the 100 MHz board clock using simple divide-by-4 logic inside `vga_sync`. If your board uses a different clock, update the divider or insert a PLL/MMCM.
- When moving to another FPGA board, ensure the `.xdc` sets the correct I/O standards (e.g., `LVCMOS33` for VGA DAC resistors).

## Future Ideas
- Re-enable and finish `Score_display.v` to drive the seven-seg display concurrently with the VGA overlay.
- Add more ghosts or smarter AI paths driven by the maze graph instead of bounding-box checks.
- Integrate sound (e.g., use the `BG Music.mp3` asset plus an I²S codec).
- Expand the maze or support scrolling resolutions beyond 640×480.

Enjoy hacking Pac-Man in HDL!

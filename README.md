# Quickshell OSK

A lightweight, floating on-screen keyboard widget built for **Quickshell**. It operates as a standalone overlay window and uses `ydotool` for broad input compatibility across Wayland compositors.

## ✨ Features

* **Wayland Native:** Runs as a `WlrLayer.Overlay` window to float above applications.
* **Touch & Mouse Friendly:**
    * **Draggable:** Grab the background to move the keyboard anywhere on screen.
    * **Resizable:** Drag the bottom-right corner to resize. The layout scales dynamically.
* **Advanced Modifiers:**
    * **3-State Logic:** Supports **Normal** (Hold), **One-Shot** (Tap once), and **Locked** (Tap twice) states for Shift, Ctrl, and Alt.
    * **Visual Feedback:** Keys change color to indicate active (Blue) or locked (Purple) states.
* **Caps Lock Support:** Internal emulation to ensure reliable capitalization.
* **Auto-Repeat:** Holding Backspace deletes text continuously.

## 🛠️ Requirements

1.  **Quickshell**: The shell environment.
2.  **ydotool**: Required for injecting keystrokes.
    * *Note:* The `ydotoold` daemon must be running for input to work.

## 📂 Installation

1.  Clone this repository into your Quickshell config folder (e.g., `~/.config/quickshell/osk`):

    ```text
    ~/.config/quickshell/osk/
    ├── OnScreenKeyboard.qml
    ├── OskContent.qml
    ├── OskKey.qml
    └── layouts.js
    ```

2.  **Start the Daemon:**
    Ensure the backend service is active.
    ```bash
    systemctl --user enable --now ydotool
    ```

3.  **Usage:**
    Import and instantiate the component in your main `shell.qml`:

    ```qml
    import QtQuick
    import Quickshell
    import "./osk" 

    ShellRoot {
        // The keyboard manages its own window and positioning
        OnScreenKeyboard {
            id: osk
            
            // Optional: Bind visibility to a variable to toggle it
            // visible: true 
        }
    }
    ```

## ⚙️ Configuration

### Layouts
Key layouts are defined in `layouts.js`. The default layout is "English (US)". You can customize keys or add new language maps by editing the `byName` object.

### Customization
* **Dimensions:** Default start size is set in `OnScreenKeyboard.qml` (`currentW`, `currentH`).
* **Colors:** Appearance is defined in `OskKey.qml` (Backgrounds, Borders, Text).

## 🧩 Modifiers Guide

| State | Action | Visual Color | Behavior |
| :--- | :--- | :--- | :--- |
| **Off** | - | Dark Gray | Normal typing. |
| **One-Shot** | Tap Modifier x1 | Blue | Modifier applies to the *next* key only, then turns off. |
| **Locked** | Tap Modifier x2 | Purple | Modifier stays active until clicked again. |

# Erlang Android Example App

> **Note:** This project has been transitioned to **Erlang**. While some files and packages still use Elixir-based naming (e.g., `io.elixirdesktop`), the backend logic and runtime are purely Erlang-focused.

This Android Studio project demonstrates how to run an Erlang/OTP application on an Android device, using a WebView as the primary user interface.

## Recent Fixes & Robustness

To address `net::err_connection_refused` errors during the initial startup, the following improvements were implemented:

1.  **Boot Order Swap**: Updated `erlang_app_sup.erl` to start the `web_page` server before the `android_bridge`. This ensures the server begins initialization while the bridge is still setting up its connection.
2.  **Delayed Initial Load**: Modified `android_bridge.erl` to wait 500ms before sending the initial `load_url` command. This delay gives the Erlang web server sufficient time to bind to its port and start listening.
3.  **Automatic Retry**: Added a retry mechanism in `MainActivity.kt`. If the Android WebView encounters a connection error (`ERROR_CONNECT` or `ERROR_HOST_LOOKUP`) when attempting to reach the local server, it will automatically retry after a 500ms delay.
4.  **Route Update**: Changed the default landing page to the root `/`, which now displays an `erlang:memory()` status table.

These changes significantly improve the reliability of the startup sequence, mitigating race conditions between the Erlang backend and the Android frontend.

## How the Erlang Code Works

The Erlang side of the application is composed of three main modules:

*   **`erlang_app_sup`**: The top-level supervisor that manages the `web_page` and `android_bridge` processes.
*   **`web_page`**: A lightweight web server (utilizing Erlang's built-in `inets`) that serves the application's UI.
*   **`android_bridge`**: Manages the communication channel between the Erlang VM and the Android environment via a TCP socket, allowing the backend to trigger actions like page loads in the WebView.

## Runtime Notes

The pre-built Erlang runtime for Android ARM/ARM64/x86 is embedded in this repository. These native runtime files include Erlang/OTP and the `exqlite` NIF for SQLite support. These runtimes are generated via the [Desktop Runtime](https://github.com/elixir-desktop/runtimes) CI.

Because Erlang/OTP has native hooks for networking and cryptography, the Erlang version used for local development must match the bundled runtime (currently **Erlang/OTP 26.2.5**). A `.tool-versions` file is included for use with `asdf`.

## How to build & run

1.  **Install Android Studio + NDK.**
2.  **Install [asdf](https://asdf-vm.com/):**

    ```shell
    sudo apt install curl
    curl --silent --location -o - https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz | tar xzf - -C ~/bin/
    export PATH="$PATH:~/bin"
    ```

3.  **Install the matching Erlang version:**

    ```shell
    asdf plugin add erlang
    cd app/erlang-app/erlang_app && asdf install
    ```

4.  **Open the project** in Android Studio and run it on a device or emulator.

## Customize app name and branding

Update the following to change the identity of your app:

1.  **App Name**: [strings.xml](app/src/main/res/values/strings.xml) and [settings.gradle](settings.gradle)
2.  **Package Names**: [Bridge.kt](app/src/main/java/io/elixirdesktop/example/Bridge.kt) and [MainActivity.kt](app/src/main/java/io/elixirdesktop/example/MainActivity.kt)
3.  **Icons**: [ic_launcher_foreground.xml](app/src/main/res/drawable-v24/ic_launcher_foreground.xml) and [ic_launcher-playstore.png](app/src/main/ic_launcher-playstore.png)
4.  **Colors**: [colors.xml](app/src/main/res/values/colors.xml) and [ic_launcher_background.xml](app/src/main/res/values/ic_launcher_background.xml)

## Screenshots

![Icons](/icon.jpg?raw=true "App in Icon View")
![App](/app.png?raw=true "Running App")

## Architecture

![Architecture](/android_elixir.png?raw=true "Architecture Diagram")

The Android App initializes the Erlang VM and provides a `BRIDGE_PORT` environment variable. The Erlang `android_bridge` connects to this port to establish a TCP channel for cross-environment communication, redirecting UI-related calls to the Android `Bridge.kt` implementation.

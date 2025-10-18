<img width="338" height="338" alt="logofinal" src="https://github.com/user-attachments/assets/fbaff819-7e97-4c07-ac4a-6a61f41355c0" />


# spotictl.sh - Spotify Control from your Terminal

Simple bash script for macOS that employs Spotify's APIs to control spotify players with your keyboard (works best with librespot + spotify-qt).

(REQUIRES PREMIUM)

> Due to its online nature, pausing may take up to a second to work.


![Version](https://img.shields.io/badge/version-3.0.4-blue.svg)

---

## 🚀 Features

* **Playback Control**: Skip to the next track, go back to the previous one, and toggle between play/pause.
* **Status Check**: Get detailed information about the current playback status in JSON format.
* **Smart Device Detection**: Prioritizes control over the currently active device.
* **Efficient Token Management**: Uses a caching system for the access token to minimize API calls, making it very fast.
* **GUI & Keyboard Integration**: Can be easily integrated with tools like [BetterTouchTool](https://folivora.ai/) to create a keyboard-driven GUI for apps like `spotify-qt`.

>BTT preset is provided.

---

## 📋 Requirements

To run this script, you need the following tools installed on your system:

* **bash**: The shell interpreter to execute the script.
* **curl**: For making requests to the Spotify API.
* **jq**: An essential tool for parsing the JSON responses from the API.

You can install `jq` on most systems using a package manager. For example:
```bash
# On Debian/Ubuntu
sudo apt-get install jq

# On macOS (with Homebrew)
brew install jq
```

---

## 🔧 Installation & Setup

Some initial setup is required, I have encountered no need for changes as of yet.

### Step 1: Download the Script and Make it Executable

1.  Save the script's code into a file named `spotictl.sh`.
2.  Open a terminal and grant it execution permissions:
    ```bash
    chmod +x spotictl.sh
    ```

### Step 2: Get Spotify API Credentials

1.  **Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)** and log in.
2.  Click **"Create App"**. Give it a name (e.g., "Terminal Control") and a description.
3.  Once the app is created, you will see your **Client ID** and have an option to view your **Client Secret**. **Copy both of these values**.
4.  Next, click **"Edit Settings"**. In the **"Redirect URIs"** field, add the following URL and save your changes:
    ```
    http://127.0.0.1:8888
    ```

<img width="1438" height="868" alt="Captura de pantalla 2025-10-18 a las 22 17 19" src="https://github.com/user-attachments/assets/a424627a-b2cc-490e-9f7b-faa4d1a2fb9a" />


### Step 3: Get Your Refresh Token

This is a **one-time process**.

1.  **Construct the authorization URL**. You need to add scopes, which are the permissions your script needs. For this script, you need `user-read-playback-state` and `user-modify-playback-state`. The final URL structure is:

    `https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://localhost:8888/callback&scope=user-read-playback-state%20user-modify-playback-state`

2.  **Replace `YOUR_CLIENT_ID`** in the URL above with your actual Client ID, then paste the full URL into your browser and visit it.

3.  You will be prompted to authorize the application. Accept it.
4.  You will be redirected to a page that cannot be displayed (this is normal). **Look at your browser's address bar**. You will see a URL like this:
    `http://localhost:8888/callback?code=A_VERY_LONG_CODE_WILL_BE_HERE`
5.  **Copy that `code`** from the URL. It is temporary and only lasts for a few minutes.
6.  **Run the following command in your terminal**. Replace `YOUR_CLIENT_ID`, `YOUR_CLIENT_SECRET`, and `CODE_FROM_URL` with your credentials and the code you just copied.

    ```bash
    curl -s -X POST -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
      -d grant_type=authorization_code \
      -d code="CODE_FROM_URL" \
      -d redirect_uri="http://localhost:8888/callback" \
      [https://accounts.spotify.com/api/token](https://accounts.spotify.com/api/token)
    ```

7.  The response will be a JSON object. Find the value for **`"refresh_token"`** and **copy it**. This is the token you need!

### Step 4: Edit the Script

Open the `spotictl.sh` file with a text editor and fill in the first three variables with the credentials you've obtained:

```bash
# --- YOUR CREDENTIALS ---
CLIENT_ID="YOUR_CLIENT_ID"
CLIENT_SECRET="YOUR_CLIENT_SECRET"
REFRESH_TOKEN="YOUR_REFRESH_TOKEN"
```

## 🎮 Usage

Using the script is straightforward. Just run it with one of the following commands:

* **Skip to the next song:**
    ```bash
    ./spotictl.sh next
    ```

* **Go back to the previous song:**
    ```bash
    ./spotictl.sh prev
    ```

* **Pause or resume playback:**
    ```bash
    ./spotictl.sh pause
    ```

* **View the current playback status:**
    ```bash
    ./spotictl.sh status
    ```
---

## ⌨️ Keyboard Integration (macOS)

You can achieve a powerful, GUI-like experience by integrating this script with **[BetterTouchTool](https://folivora.ai/)**. This allows you to control Spotify clients like `spotify-qt` or the official app using keyboard shortcuts.

The manual process is as follows:

1.  **Open BetterTouchTool**.
2.  Go to the "Keyboard Shortcuts" section.
3.  Create new shortcuts (e.g., `shift + F8` for play/pause, `shift + F9` for next track).
4.  For the action assigned to each shortcut, choose **"Run Terminal Command"**.
5.  Change as you wish.

I uploaded a `.bttpreset` that does this automatically and adds a cool html UI too :) (The key words are in Spanish, I may change it for this repo but you can easily modify the HTML in the floating WebView).

<img width="114" height="105" alt="imagen" src="https://github.com/user-attachments/assets/514d0a30-d57d-4586-9073-9079c1dbf93f" />




---

## 📝 License

This project is released under **The Unlicense**.

# SwiftGodot Apple Sign-In Library ✨

<div align="center">
  
  ![Swift](https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)
  ![Godot](https://img.shields.io/badge/Godot-478CBF?style=for-the-badge&logo=GodotEngine&logoColor=white)
  ![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)
  
  **A lightweight, easy-to-integrate library for implementing Apple Sign-In with Godot 4.3+ on iOS**
</div>



## 📂 Project Structure



```
addons/apple_sign_in/
  ios/
    AppleSignInLibrary.framework/
      # Apple Sign-In (SwiftGodot)

      Small Swift extension that adds "Sign in with Apple" support for Godot via SwiftGodot.

      Quick — build + produce distributable in dist/

      ```bash
      chmod +x ./build.sh
      ./build.sh release
      ```

      What you get (dist/ layout)
      - dist/addons/apple_sign_in/
        - AppleSignInLibrary.gdextension
        - ios/AppleSignInLibrary.framework
        - macos/AppleSignInLibrary.framework
      - dist/samples/
        - sample_login.gd

      How to use
      1. Copy `dist/addons/apple_sign_in` into your Godot project at `res://addons/`
      2. Open Godot, the `.gdextension` is already pre-configured for iOS and macOS paths

      CI
      - The repository CI builds both platforms and uploads `dist/` as an artifact on push/PR/dispatch

      Notes
      - macOS target requires macOS 14+ (matches SwiftGodot)
      - For macOS/iOS apps, enable "Sign in with Apple" capability and proper entitlements in the host app
## 🎮 Try My Games!

<div align="center">
  <h1>See this plugin in action and support my work!</h1>
  
  <table>
    <tr>
      <td align="center">
        <img src="https://play-lh.googleusercontent.com/l-usbpBq0OuurA1e9FJSlnnVVa1HQpcUCMv_RlM63zk7jGUvXRC10Z9hDuqA83DTU6A=w240-h480-rw" width="120" height="120"><br>
        <b>Ludo World War</b><br>
        <a href="https://apps.apple.com/np/app/ludo-app-gold/id6504749605">
          <img src="https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg" width="120">
        </a>
      </td>
      <td align="center">
        <img src="https://play-lh.googleusercontent.com/l-usbpBq0OuurA1e9FJSlnnVVa1HQpcUCMv_RlM63zk7jGUvXRC10Z9hDuqA83DTU6A=w240-h480-rw" width="120" height="120)" width="120" height="120"><br>
        <b>Ludo World War</b><br>
        <a href="https://play.google.com/store/apps/details?id=com.ludosimplegame.ludo_simple">
          <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" width="140">
        </a>
      </td>
    </tr>
  </table>
  
  ⭐ **Your ratings & reviews help tremendously!** ⭐
  
  Help us grow and bring you more amazing features!
</div>

---

<p align="center">
  Enjoy coding & gaming! 🎮🚀
</p>

# Krypt

Krypt is a SwiftUI-based iOS app for experimenting with text encryption for the paranoid.
It provides a clean “workspace” interface for encrypting and decrypting text, managing keys and viewing a history of operations.

> **Note:** This app is primarily an educational / utility tool. Only the **Secure** mode is suitable for real security. The **XOR** mode is explicitly labeled as non-secure and for learning purposes only. The logic provided by "XOR" was provided by Analyst "Fajar Sajid" which helped create the ecryption for the educational bit.

---

## Features

- **Secure encryption mode**
  - Uses ChaCha20-Poly1305 (AEAD) under the hood
  - 32-byte Base64 key support
  - Optional Hex output formatting
  - Per-message nonces and integrity protection

- **XOR mode (educational)**
  - Simple integer key
  - Base64 ciphertext
  - Useful for understanding basic symmetric transformations (not real security)

- **Workspace UI**
  - Message input and output with `TextEditor`
  - Mode picker (`Secure` / `XOR`) via segmented control
  - Per-mode key input section
  - Inline toasts and banners for feedback and error reporting
  - Clipboard integration (paste into message, copy output)

- **Key management**
  - Generate secure Base64 keys
  - Validate 32-byte Base64 keys
  - Save / load secure key via Keychain
  - Key strength indicator (valid / invalid)

- **History**
  - History icon in the navigation bar
  - History sheet listing past operations (mode, time, key hint, previews)
  - “Reuse” action to load previous output back into the workspace

- **Settings**
  - Settings icon in the navigation bar
  - Uses a separate `SettingsView` (not defined in this file, but integrated)
  - Supports `@AppStorage`-backed preferences such as:
    - Auto-clear message after encryption
    - Auto-copy output after encryption
    - Auto-load secure key on launch
    - Default output format

---

## Workspace Layout

The main screen is implemented in `KryptWorkspaceView` and is structured as:

1. **Navigation bar**
   - Title: `Workspace`
   - Trailing icons:
     - ⏰ `clock` icon → opens History
     - ⚙️ `gearshape` icon → opens Settings

2. **Header**
   - Title: “Krypt Console”
   - Subtitle: “Choose a mode, provide a key, then encrypt or decrypt.”

3. **Mode picker**
   - `Secure`
   - `XOR (educational)`

4. **Warning banner (for non-secure modes)**
   - Shown when `XOR` is active
   - Clarifies that it is not safe for real data

5. **Message section**
   - “Message” label
   - Multi-line `TextEditor` for plain text or ciphertext
   - “Paste → Message” button to pull from clipboard

6. **Key section**
   - **Secure mode**
     - Header: “Secure Key”
     - “Generate Key” button (wand icon)
     - TextField for Base64 key
     - Key validity indicator (valid / invalid)
     - “Save” / “Load” buttons for Keychain integration
   - **XOR mode**
     - Header: “Key (single integer, e.g. 357)”
     - TextField for integer key

7. **Output format**
   - Segmented picker:
     - `Base64`
     - `Hex`
   - Internally still supports a `pretty` case for backward compatibility, although it is not exposed in the UI.

8. **Actions**
   - `Encrypt` (primary)
   - `Decrypt` (secondary)
   - Large control size for easy tap targets

9. **Output section**
   - “Output” label
   - Multi-line `TextEditor` (read/write)
   - “Copy Output” button to copy to clipboard

10. **Footer hint**
    - Contextual hint based on mode
    - Secure: informs about AEAD + nonces
    - XOR: reminds to use same mode & key for decryption
   
      *Credits
      Creator: Momin Waleed
      Xor Logic: Fajar Sajid

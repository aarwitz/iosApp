# Elite Pro AI+ Demo (SwiftUI)

This is a **demo-only** SwiftUI codebase you can drop into a brand-new Xcode iOS project.

## Fastest way to run (5 minutes)

1. Open **Xcode** → **File → New → Project…**
2. Choose **iOS → App**
3. Product Name: `EliteProAIDemo`
4. Interface: **SwiftUI** · Language: **Swift**
5. Create the project.
6. In Xcode’s Project Navigator, **delete** the auto-created `ContentView.swift` (optional).
7. Drag the entire `EliteProAIDemo/` folder from this zip into your Xcode project (the folder that contains `.swift` files).
   - When prompted, check **“Copy items if needed”**
   - Make sure your app target is checked.
8. In your auto-created `EliteProAIDemoApp.swift`, replace its contents with the file `EliteProAIDemoApp.swift` from this folder (or just drag it in and keep the newest one).
9. Run ▶️ in the iPhone simulator.

## What you get
- Bottom tab bar: **Challenges, Connector, Rewards, Groups**
- Home screen (“My Wellness”) matching your mockups:
  - Profile card
  - “Healthy Habit Credits” progress bar
  - Buttons for coaching, nutrition, group classes, etc.
  - Chat preview with “Just now” bubbles
- Hamburger side menu that opens/closes and navigates (switches tabs / opens community feed)
- Mock local data with **simple JSON persistence** in Documents (so edits persist across runs)

## Notes
- This is a **working demo** meant to look/feel like your screenshots, not a production architecture.
- Everything is SwiftUI; no network calls.

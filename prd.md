# Product Requirements Document: Minimal Journal App

## Document Information
**Product Name:** Minimal Journal  
**Version:** 1.0 (MVP)  
**Platform:** Mobile (iOS & Android)  
**Technology Stack:** Flutter  
**Document Date:** January 29, 2026  
**Document Owner:** Product Team  

---

## 1. Executive Summary

Minimal Journal is a distraction-free, offline-first mobile journaling application designed to provide users with a calm, focused writing environment. The app embraces radical simplicity by stripping away unnecessary features and focusing solely on the core journaling experience. With no account requirements, no cloud sync, and no internet dependency, Minimal Journal offers complete privacy and control over personal reflections.

The application targets users seeking a digital journaling solution that respects their privacy, encourages focused writing sessions, and provides an elegant, minimalist interface free from the complexity and feature bloat of traditional journaling apps.

---

## 2. Product Vision & Goals

### 2.1 Vision Statement
To create the most focused, distraction-free journaling experience that puts writing first and everything else second.

### 2.2 Primary Goals
- Provide a completely offline journaling solution with zero internet dependency
- Enable focused writing sessions through subtle timer functionality
- Maintain radical simplicity through minimalist design and limited feature set
- Ensure user privacy through local-only data storage
- Create a calming, monotone visual experience that encourages reflection

### 2.3 Success Metrics
- User retention rate after first week
- Average session duration
- Number of entries created per active user
- App store ratings and reviews
- Daily active users (DAU) and monthly active users (MAU)

---

## 3. Target Audience

### 3.1 Primary Users
- Individuals seeking private, offline journaling solutions
- Users who value simplicity over feature-rich applications
- People practicing mindfulness and focused writing
- Privacy-conscious users who prefer local data storage
- Minimalism enthusiasts

### 3.2 User Personas

**Persona 1: The Mindful Writer**
- Age: 25-40
- Needs: Distraction-free environment for daily reflection
- Pain Points: Overwhelmed by feature-heavy apps, concerned about privacy
- Goals: Build consistent journaling habit with minimal friction

**Persona 2: The Privacy Advocate**
- Age: 30-50
- Needs: Complete control over personal data
- Pain Points: Distrust of cloud storage and data collection
- Goals: Keep thoughts entirely private and offline

**Persona 3: The Focused Creator**
- Age: 20-35
- Needs: Timed writing sessions to maintain productivity
- Pain Points: Easily distracted by notifications and app complexity
- Goals: Complete focused writing sessions consistently

---

## 4. Technical Specifications

### 4.1 Platform Requirements
- **Platforms:** iOS and Android
- **Framework:** Flutter
- **Minimum iOS Version:** iOS 12.0+
- **Minimum Android Version:** Android 5.0 (API level 21)+
- **Device Support:** Standard phone sizes (no tablet-specific optimization required for MVP)
- **Orientation:** Portrait mode (primary), with portrait-only lock recommended

### 4.2 Technical Architecture
- **Storage:** Local SQLite database for entry persistence
- **State Management:** Provider/Riverpod/Bloc (to be determined during development)
- **Auto-save Mechanism:** Background save every 2 seconds while typing
- **Data Model:** Single Entry table with id, body, createdAt, updatedAt fields

### 4.3 Performance Requirements
- App launch time: Under 2 seconds on mid-range devices
- Auto-save operation: Must not interrupt typing experience
- List view scrolling: 60fps on standard devices
- Entry loading time: Instant (under 100ms)

### 4.4 Storage Considerations
- No imposed character limit per entry
- Estimated storage: ~1KB per 500-word entry
- Expected capacity: Thousands of entries without performance degradation

---

## 5. Core Features & Functionality

### 5.1 Entry Creation & Editing

#### 5.1.1 New Entry Creation
**User Flow:**
1. User launches app or taps + icon from list view
2. App presents blank writing canvas
3. User begins typing immediately (no title, no prompts)
4. Entry auto-saves every 2 seconds
5. CreatedAt timestamp automatically assigned on first character input

**Technical Requirements:**
- Instant text input focus on new entry screen
- Smooth, responsive typing experience with no lag
- Auto-save must be imperceptible to user
- CreatedAt timestamp uses device local time

#### 5.1.2 Editing Existing Entries
**User Flow:**
1. User taps entry from list view
2. Entry opens in edit mode with full text displayed
3. User can modify text freely
4. Changes auto-save every 2 seconds
5. UpdatedAt timestamp refreshed on any modification

**Technical Requirements:**
- Preserve cursor position during auto-saves
- No visual indication of save operation (completely silent)
- UpdatedAt timestamp tracks last modification time

#### 5.1.3 Auto-Save Mechanism
**Behavior:**
- Triggers every 2 seconds after user stops typing
- Silent operation with no UI feedback
- Preserves scroll position and cursor location
- Handles rapid typing without data loss
- Graceful degradation if save fails (retry mechanism)

---

### 5.2 Writing Interface

#### 5.2.1 Text Canvas
**Design Specifications:**
- Full-screen writing area with minimal chrome
- Maximum text area utilization
- Clean, distraction-free environment
- No borders, dividers, or unnecessary visual elements
- Comfortable line height (1.5x - 1.6x) for readability

#### 5.2.2 Typography System

**Font Options:**
1. **Inter** - Default, modern sans-serif
2. **Instrument Sans** - Alternative sans-serif for variety
3. **Times New Roman** - Classic serif for traditional feel

**Font Size Options:**
- 16px - Default (balanced readability)
- 18px - Medium (enhanced readability)
- 20px - Large (maximum readability)

**Implementation Requirements:**
- Smooth font switching without layout shift
- Font preference persists across sessions
- Font applies globally to all entries
- Instant font change response (no loading state)

#### 5.2.3 Dynamic Bottom Toolbar

**Overview:**
A persistent, compact toolbar that sticks to the bottom of the screen containing all essential controls in a single row. The toolbar intelligently shows and hides based on user typing activity to maximize writing space during active composition.

**Visibility Logic:**

**Active Typing State:**
- Definition: User has typed something in the last 1 second
- Behavior: Toolbar animates out and becomes invisible
- Purpose: Maximize screen space for uninterrupted writing

**Inactive State:**
- Definition: User has not typed for more than 1 second
- Behavior: Toolbar animates in and becomes visible
- Purpose: Provide easy access to controls without manual toggling

**Animation Specifications:**

**Slide Out (Active Typing):**
- Direction: Top to bottom (toolbar slides down off screen)
- Duration: 1 second
- Easing: Smooth, gentle ease-out curve
- Opacity: Fades out simultaneously (1 → 0)
- Combined effect: Slide + fade creates smooth disappearance

**Slide In (Inactive):**
- Direction: Bottom to top (toolbar slides up into view)
- Duration: 1 second
- Easing: Smooth, gentle ease-in curve
- Opacity: Fades in simultaneously (0 → 1)
- Combined effect: Slide + fade creates smooth appearance
- Trigger: Automatically when typing stops for 1 second

**Layout Structure:**
Horizontal row containing 4 control sections from left to right:

**Section 1: Timer Controls**
- Three duration buttons displayed inline: "10" "20" "30"
- Format: Numbers only, minimal styling
- Selected duration visually highlighted (underline, border, or background)
- Start/Stop button adjacent to duration selector
- Start button: Play icon (▶) or "Start" text
- Stop button: Stop icon (■) or "Stop" text
- Active timer countdown displayed when running: "15:23" format
- Timer countdown replaces or appears near duration selector

**Section 2: Font Size Selector**
- Three size buttons: "16" "18" "20"
- Format: Numbers only
- Currently selected size highlighted (underline, border, or background)
- Single-tap to change size with instant application

**Section 3: Font Family Selector**
- Three font buttons with clear labels
- Options displayed as:
  - Full names: "Inter" "Inst Sans" "Times" OR
  - Abbreviations: "I" "IS" "T" OR
  - Sample text in each font: "Aa" rendered in respective font
- Currently selected font highlighted
- Single-tap to change font with instant application

**Section 4: Theme Toggle**
- Binary toggle control for Light/Dark mode
- Visual representation:
  - Icon-based: ☀ (sun) for light, ☾ (moon) for dark OR
  - Text-based: "L" for light, "D" for dark OR
  - Toggle switch with clear light/dark indication
- Single-tap to switch between themes
- Immediate theme application across entire app

**Design Requirements:**

**Physical Dimensions:**
- Total height: Approximately 40-48px
- Full width of screen (edge to edge or with minimal padding)
- Touch targets: Minimum 44x44px for accessibility despite compact design

**Visual Style:**
- Extremely compact and space-efficient
- Clean, uncluttered layout
- Clear visual separation between sections (subtle dividers or spacing)
- Follows strict monotone palette:
  - Light mode: Black controls on white/light gray background
  - Dark mode: White controls on black/dark gray background
- Subtle background to distinguish from writing canvas:
  - Light mode: #F5F5F5 or white with subtle top border/shadow
  - Dark mode: #1A1A1A or black with subtle top border/highlight

**Typography in Toolbar:**
- Small, legible font (10-12px for labels)
- Slightly larger for active/selected states (12-14px)
- High contrast for readability
- Consistent alignment and spacing

**Spacing & Layout:**
- Even distribution of all four sections across width
- Equal padding on left and right edges (16-24px)
- Consistent vertical centering of all controls
- Tight but comfortable horizontal spacing between sections

**State Indicators:**
- Selected options clearly highlighted with:
  - Background color change
  - Underline or border
  - Slight size or weight increase
- Active timer shows different visual state from inactive
- Smooth transitions between all state changes (200-300ms)

**Interaction Feedback:**
- Brief visual feedback on tap (ripple effect or highlight)
- Instant response to user interaction
- No loading states or delays
- Haptic feedback optional (subtle vibration on selection)

**Technical Requirements:**
- Toolbar must not interfere with text input
- Keyboard appearance should not affect toolbar visibility logic
- Toolbar animations must be smooth at 60fps
- State of toolbar (visible/hidden) recalculated continuously based on typing activity
- 1-second timer starts/resets with each keystroke
- Toolbar completely hides off-screen when invisible (not just transparent)

**Keyboard Interaction:**
- When keyboard appears, toolbar should remain at bottom of visible screen area
- Toolbar sits above keyboard (not obscured by it)
- Toolbar visibility still controlled by typing activity even when keyboard is visible

---

### 5.3 Theme System

#### 5.3.1 Light Mode
**Color Specifications:**
- Background: Pure white (#FFFFFF) or off-white (#FAFAFA)
- Text: Pure black (#000000) or near-black (#0A0A0A)
- Accent elements: Black or dark gray (#333333)
- Borders/dividers: Light gray (#E0E0E0)

#### 5.3.2 Dark Mode
**Color Specifications:**
- Background: Pure black (#000000) or near-black (#121212)
- Text: Pure white (#FFFFFF) or off-white (#F5F5F5)
- Accent elements: White or light gray (#CCCCCC)
- Borders/dividers: Dark gray (#2A2A2A)

#### 5.3.3 Theme Behavior
- Theme preference persists across app restarts
- Theme change applies instantly across entire app
- System theme detection (optional consideration for future)
- Smooth transition animation between themes

---

### 5.4 Focus Timer

#### 5.4.1 Timer Durations
**Fixed Options:**
- 10 minutes
- 20 minutes
- 30 minutes

**Note:** Timer controls are integrated into the dynamic bottom toolbar (see section 5.2.3)

#### 5.4.2 Timer Display
**Visual Design:**
- Integrated into dynamic bottom toolbar
- Small, subtle countdown display: MM:SS format
- Appears when timer is active
- Positioned near timer controls in toolbar
- Minimal contrast to maintain non-distracting aesthetic
- Clearly visible but not prominent

**Examples:**
- "20:00" when starting 20-minute session
- "08:23" during countdown
- "00:00" when complete

**Display Location:**
Timer countdown is displayed within the bottom toolbar, either replacing the duration buttons or appearing adjacent to the Start/Stop button when active.

#### 5.4.3 Timer Controls

**All timer controls are housed in the dynamic bottom toolbar (Section 5.2.3).**

**Start Timer:**
- User selects duration from toolbar options (10, 20, or 30)
- User taps Start button (play icon or text)
- Timer begins countdown immediately
- Duration buttons highlight selected time
- Countdown display appears in toolbar

**Stop Timer:**
- Stop button visible when timer is active
- Single tap ends timer session completely
- Timer resets to 00:00
- Returns to duration selection state
- No persistent timer state after stopping

**Pause Timer:**
- Pause functionality removed for simplicity
- Only Start and Stop controls available
- Simplifies user interface and reduces complexity

**Reset Timer:**
- Available implicitly through Stop button
- Stopping timer resets it to initial state
- User can select new duration and restart

#### 5.4.4 Timer Completion
**Behavior:**
- When timer reaches 00:00, display subtle notification via top snackbar
- Notification message: "Timer complete" or similar minimal text
- No audio alert (completely silent notification)
- Snackbar appears at top of screen (see Section 5.8 for snackbar specifications)
- Message displays for 3-5 seconds, then fades out
- Timer automatically resets to 00:00 and returns to duration selection
- User can continue writing without any interruption

**Key Principle:**
Timer is a gentle guide, not a deadline. It should encourage focus without creating pressure or disrupting flow state. The completion notification is deliberately subtle and non-intrusive.

#### 5.4.5 Timer Persistence
- Timer state resets if user navigates away from entry
- Timer does not persist across app closes
- Timer is session-specific, not entry-specific

---

### 5.5 Entry List View

#### 5.5.1 List Display
**Layout:**
- Full-screen scrollable list
- Single-column layout
- Entries sorted by createdAt (most recent first)
- Clean, card-based or divider-separated design

**Entry Preview:**
- Display truncated first line of entry body
- Show createdAt timestamp
- Subtle visual hierarchy between preview and timestamp
- No character limit on preview (truncate with "..." if needed)

**Example Entry Card:**
```
Today was an interesting day at work and I...
Jan 29, 2026 • 2:45 PM
```

#### 5.5.2 Entry Interaction
**Tap Entry:**
- Opens entry in edit mode
- Full entry text displayed
- Immediate keyboard focus (optional, may be distracting)

**No Gestures Required:**
- No swipe-to-delete
- No pull-to-refresh
- All actions accessible via tap

#### 5.5.3 Empty State
**First Launch:**
- No onboarding or tutorial
- Immediately presents blank writing canvas
- User can start typing instantly

**Empty List View:**
- Display when user navigates to list with no entries
- Simple message: "No entries yet" or similar
- + button clearly visible to create first entry

---

### 5.6 Entry Actions

#### 5.6.1 Delete Entry
**User Flow:**
1. User initiates delete action (button or menu item in entry view)
2. Confirmation popup appears: "Delete this entry?"
3. Popup provides two options: "Cancel" and "Delete"
4. If Delete selected, entry permanently removed
5. User returned to list view
6. Entry removed from list immediately

**Confirmation Popup Design:**
- Simple, minimal design
- Clear action buttons
- Dismiss on tap outside or Cancel
- No undo functionality (permanent deletion)

#### 5.6.2 Copy Entry
**User Flow:**
1. User taps "Copy" action from entry menu
2. Entire entry body copied to device clipboard
3. Top snackbar appears with message: "Copied to clipboard" (see Section 5.8)
4. Confirmation displays for 3 seconds
5. User can paste content in external apps

**Use Cases:**
- Sharing entry with others
- Moving content to another app
- Backup individual entries manually

---

### 5.7 New Entry Creation (+ Icon)

**Icon Placement:**
- Visible on list view screen
- Floating action button (FAB) or header button
- Always accessible from list view

**Behavior:**
- Single tap creates new blank entry
- Navigates to entry edit screen
- No pre-filled content (completely blank)
- Immediate typing focus

---

### 5.8 Custom Top Snackbar System

**Overview:**
The app uses a custom snackbar notification system that appears at the TOP of the screen instead of the traditional bottom placement. This design choice ensures notifications never interfere with the bottom toolbar or keyboard area.

#### 5.8.1 Purpose
Top snackbars provide non-intrusive feedback for:
- Timer completion notifications
- Entry copy confirmations ("Copied to clipboard")
- Error messages (storage failures, etc.)
- Success confirmations (entry deleted, settings saved, etc.)

#### 5.8.2 Visual Design

**Positioning:**
- Appears at top of screen
- Below status bar (safe area inset respected)
- Full width or slightly inset from edges (16-24px padding)
- Fixed position, does not scroll with content

**Dimensions:**
- Height: 40-56px (depends on text content)
- Width: Screen width minus horizontal padding
- Rounded corners on bottom: 8-12px radius
- Flat top edge (sits flush against safe area)

**Visual Style:**
- Minimal, clean design consistent with app aesthetic
- Follows monotone color scheme:
  
  **Light Mode:**
  - Background: Black (#000000) or dark gray (#1A1A1A)
  - Text: White (#FFFFFF)
  - Creates high contrast against light background
  
  **Dark Mode:**
  - Background: White (#FFFFFF) or light gray (#F5F5F5)
  - Text: Black (#000000)
  - Creates high contrast against dark background

- Subtle shadow or border to ensure visibility
- No icons or close buttons (dismisses automatically)
- Single line of text, centered or left-aligned

**Typography:**
- Font size: 14-16px
- Font weight: Regular or medium
- Letter spacing: Comfortable readability
- Text truncation if too long (should be kept short)

#### 5.8.3 Animation Behavior

**Appearance (Slide In):**
- Direction: Top to bottom (slides down from above screen)
- Duration: 300-400ms
- Easing: Ease-out curve
- Opacity: Fades in from 0 to 1 simultaneously
- Starts above screen, slides into view below status bar

**Display:**
- Remains visible for configurable duration:
  - Standard messages: 3 seconds
  - Timer completion: 3-5 seconds
  - Error messages: 4-5 seconds
- No user interaction required (auto-dismisses)
- Tapping snackbar dismisses it immediately (optional feature)

**Dismissal (Slide Out):**
- Direction: Bottom to top (slides up and disappears)
- Duration: 300-400ms
- Easing: Ease-in curve
- Opacity: Fades out from 1 to 0 simultaneously
- Slides up until completely off screen

#### 5.8.4 Message Types

**Success Messages:**
- "Copied to clipboard"
- "Entry deleted"
- "Settings saved"

**Completion Messages:**
- "Timer complete"
- "Focus session ended"

**Error Messages:**
- "Failed to save entry"
- "Storage error"
- "Unable to copy"

**Design Consistency:**
All messages use same visual style regardless of type (no color coding). Keep messages short, clear, and actionable when needed.

#### 5.8.5 Behavior Rules

**Queueing:**
- If multiple snackbars triggered rapidly, queue them
- Display one at a time sequentially
- Previous snackbar must finish dismissing before next appears
- Maximum queue length: 3 messages (drop oldest if exceeded)

**Interaction:**
- Optional: Tap snackbar to dismiss immediately
- Swipe up gesture to dismiss (optional enhancement)
- Does not block user interaction with rest of UI
- User can continue typing while snackbar is visible

**Technical Requirements:**
- Snackbar must not affect layout of other UI elements
- Uses overlay/portal pattern to render on top of all content
- Respects safe area insets on devices with notches
- Smooth animations at 60fps
- No jank or stuttering during appearance/dismissal

**Accessibility:**
- Announce message to screen readers
- Sufficient display time for users to read
- High contrast ensures visibility
- Configurable display duration for accessibility needs

#### 5.8.6 Implementation Notes

**Development Considerations:**
- Create reusable snackbar widget/component
- Centralized snackbar service for showing messages
- Global overlay entry for rendering
- State management for queue and visibility
- Dismiss timer management

**Testing Requirements:**
- Test appearance on various screen sizes
- Verify safe area inset handling
- Test rapid successive snackbar triggers
- Verify animation smoothness
- Test accessibility features

---

## 6. User Interface Design

### 6.1 Design Principles
1. **Minimalism First:** Remove all non-essential elements
2. **Focus on Content:** Writing area is the hero element
3. **Monotone Palette:** Strict black and white color scheme
4. **Calm Aesthetic:** Soft animations, no jarring transitions
5. **Respect for Writing:** UI never interrupts the writing experience

### 6.2 Visual Language
**Characteristics:**
- Clean, uncluttered layouts
- Generous whitespace (or blackspace in dark mode)
- Subtle shadows (if any)
- Minimal iconography
- Sans-serif typography for UI elements
- Consistent spacing and alignment

### 6.3 Inspiration Reference
The provided image showcases excellent execution of minimal design principles:
- Subtle bottom toolbar with essential controls
- Clean font/size selection interface
- Non-intrusive timer display
- Dark mode with high contrast
- Floating action button for new entries

**Note:** Design should be inspired by this aesthetic but not copied exactly. Create unique visual identity while maintaining the same level of simplicity and focus.

### 6.4 Animation Guidelines
- Subtle, purposeful animations only
- Smooth transitions (200-300ms duration)
- No excessive or playful animations
- Bottom sheet slides with gentle easing
- Theme transition fades (100-150ms)

---

## 7. Data Management

### 7.1 Data Model

**Entry Schema:**
```
Entry {
  id: String (UUID)
  body: String (full entry text)
  createdAt: DateTime (ISO 8601 format)
  updatedAt: DateTime (ISO 8601 format)
}
```

**User Preferences Schema:**
```
Preferences {
  fontFamily: String (inter/instrumentsans/timesnewroman)
  fontSize: Integer (16/18/20)
  theme: String (light/dark)
}
```

### 7.2 Storage Implementation
- Local SQLite database
- Database stored in app's private directory
- No cloud sync or external storage access
- Database encrypted at OS level (iOS/Android default)

### 7.3 Data Operations

**Create Entry:**
- Generate UUID on creation
- Assign createdAt on first character input
- Initialize updatedAt same as createdAt

**Update Entry:**
- Modify body content
- Update updatedAt timestamp
- Maintain original createdAt

**Delete Entry:**
- Permanent removal from database
- No soft delete or recovery mechanism
- Cascade delete related data (if any)

**Query Entries:**
- Fetch all entries ordered by createdAt DESC
- Pagination if entry count exceeds 100 (performance consideration)

---

## 8. User Preferences & Persistence

### 8.1 Preference Storage
- Store in local shared preferences
- Persist independently from entry data
- Load on app initialization
- Apply immediately to UI

### 8.2 Preferences List
1. **Font Family:** Default = Inter
2. **Font Size:** Default = 16px
3. **Theme:** Default = Light Mode (or system theme if implemented)

### 8.3 Preference Application
- Changes apply instantly across app
- No "Save" button required
- Settings persist across app restarts
- Settings apply to all entries universally

---

## 9. Offline Functionality

### 9.1 Core Requirement
App must function 100% offline with zero internet dependency.

### 9.2 No Network Features
- No cloud sync
- No backups to external servers
- No analytics or tracking
- No ads or external content
- No account creation or authentication

### 9.3 Privacy Implications
- All data stored exclusively on device
- No data transmission outside device
- Complete user control over content
- Privacy by design and default

---

## 10. Edge Cases & Error Handling

### 10.1 Auto-Save Failures
**Scenario:** Auto-save fails due to storage issues
**Handling:**
- Retry save operation up to 3 times
- If all retries fail, display error via top snackbar (see Section 5.8)
- Error message: "Failed to save entry" or similar
- Prevent user from navigating away until save succeeds
- Last resort: Cache entry in memory and retry on app reopen

### 10.2 Storage Full
**Scenario:** Device storage exhausted
**Handling:**
- Detect low storage condition
- Display error via top snackbar: "Storage full"
- Prevent new entry creation until storage freed
- Allow viewing existing entries

### 10.3 Corrupted Database
**Scenario:** SQLite database corruption
**Handling:**
- Attempt database repair on app launch
- If repair fails, create new database
- Previous entries unrecoverable (acceptable for MVP)
- Future: Add export/backup for user protection

### 10.4 Timer Edge Cases
**Background Timer:**
- Timer pauses when app goes to background
- Resume timer when app returns to foreground
- Do not send notifications or run timer in background

**Rapid Timer Changes:**
- If user rapidly starts/stops timer, debounce operations
- Prevent UI glitches from rapid state changes

### 10.5 Empty Entry Handling
**Scenario:** User creates entry but types nothing
**Handling:**
- Do not create entry record until first character typed
- If user navigates away from empty entry, do not save
- Empty entries do not appear in list view

### 10.6 Very Long Entries
**Scenario:** User writes extremely long entry (10,000+ words)
**Handling:**
- No artificial character limit imposed
- Monitor performance with large entries during testing
- Optimize rendering if lag detected
- Consider pagination or lazy loading for very long texts (future)

### 10.7 Bottom Toolbar and Top Snackbar Interaction
**Scenario:** User receives notification while actively typing
**Handling:**
- Top snackbar can appear even when bottom toolbar is hidden
- Snackbar and toolbar operate independently
- Snackbar appears at top of screen, does not affect toolbar behavior
- If user stops typing while snackbar is visible:
  - Bottom toolbar animates in after 1-second delay as normal
  - Snackbar remains at top until its display duration expires
- Both elements can be visible simultaneously without conflict

**Scenario:** Toolbar animation and snackbar animation overlap
**Handling:**
- Both animations run independently and smoothly
- No animation interference or jankiness
- Z-index properly layered (snackbar above all other elements)

---

## 11. Future Considerations (Post-MVP)

### 11.1 Potential Features
**NOT included in MVP but potential roadmap items:**
- Entry search functionality
- Entry tags or categories
- Export all entries (JSON, TXT, PDF)
- Backup and restore mechanism
- Entry encryption with password/biometric lock
- Writing statistics (word count, streak tracking)
- Custom timer durations
- Multiple themes beyond black/white
- iPad/tablet optimization
- System theme auto-detection
- Entry templates or prompts

### 11.2 Monetization Strategy
**Lifetime Purchase Model:**
- Single one-time payment to unlock full app
- Paywall implementation deferred to post-MVP
- Potential free tier with limitations (TBD)
- No subscriptions or recurring payments
- No ads or sponsored content

### 11.3 Platform Expansion
- Web version (potential)
- Desktop applications (potential)
- Apple Watch complication (potential)

---

## 12. Non-Functional Requirements

### 12.1 Performance
- App launch: Under 2 seconds
- Entry load: Under 100ms
- List scrolling: 60fps
- Auto-save: Imperceptible (<50ms)
- Theme change: Instant (<100ms)

### 12.2 Reliability
- Zero data loss during auto-save
- Graceful handling of storage errors
- Stable performance with 1,000+ entries
- No crashes during normal operation

### 12.3 Usability
- Intuitive interface requiring no tutorial
- Accessible to users with varying tech literacy
- Comfortable for extended writing sessions
- Minimal cognitive load

### 12.4 Accessibility
- Support for system font scaling
- High contrast mode support (dark/light themes)
- Screen reader compatibility (VoiceOver/TalkBack)
- Keyboard navigation support

### 12.5 Localization
**MVP: English Only**
Future considerations for additional languages.

---

## 13. Development Phases

### 13.1 Phase 1: Core Writing Experience (Week 1-2)
- Basic entry creation and editing
- Auto-save functionality
- Local storage implementation
- Single font and size (defaults)

### 13.2 Phase 2: Customization (Week 3)
- Font family selection (3 options)
- Font size adjustment (3 options)
- Dark mode implementation
- Settings bottom sheet UI

### 13.3 Phase 3: Entry Management (Week 4)
- Entry list view
- Entry deletion with confirmation
- Entry copy functionality
- + icon for new entries

### 13.4 Phase 4: Focus Timer (Week 5)
- Timer UI implementation
- Timer controls (start, pause, stop, reset)
- Timer completion notification
- Timer state management

### 13.5 Phase 5: Polish & Testing (Week 6-7)
- UI refinement and animation tuning
- Edge case handling
- Performance optimization
- Bug fixes and stability improvements
- User acceptance testing

### 13.6 Phase 6: Launch Preparation (Week 8)
- App store assets (icons, screenshots, descriptions)
- Beta testing with small user group
- Final QA and regression testing
- Deployment preparation

---

## 14. Success Criteria

### 14.1 Launch Criteria
- App successfully installs on iOS and Android
- Zero critical bugs or crashes
- All core features functional
- Performance meets specified benchmarks
- Passes app store review guidelines

### 14.2 User Success Metrics (3 Months Post-Launch)
- 70% user retention after 7 days
- Average session length of 5+ minutes
- 2+ entries created per active user per week
- App store rating of 4.5+ stars
- Less than 5% crash rate

### 14.3 Technical Success Metrics
- App size under 15MB
- Memory usage under 100MB during typical use
- Battery drain within acceptable range (TBD baseline)
- 99.9% successful auto-saves

---

## 15. Risks & Mitigation

### 15.1 Technical Risks

**Risk:** Data loss due to auto-save failures
**Mitigation:** Robust retry mechanism, in-memory caching, thorough testing

**Risk:** Performance degradation with large entry counts
**Mitigation:** Database optimization, pagination, performance monitoring

**Risk:** Flutter framework limitations
**Mitigation:** Early prototyping of critical features, fallback strategies

### 15.2 User Experience Risks

**Risk:** Timer feature distracts from writing
**Mitigation:** Minimal timer design, user testing to validate non-intrusiveness

**Risk:** Lack of features compared to competitors
**Mitigation:** Clear positioning as minimalist alternative, target users who value simplicity

**Risk:** Users accidentally delete entries
**Mitigation:** Confirmation popup, consider undo/trash feature in future

### 15.3 Business Risks

**Risk:** Limited monetization with one-time purchase
**Mitigation:** Price point research, potential freemium model exploration

**Risk:** Low discoverability in app stores
**Mitigation:** Strong ASO (App Store Optimization), community building, word-of-mouth strategy

---

## 16. Dependencies & Assumptions

### 16.1 Technical Dependencies
- Flutter SDK (stable channel)
- SQLite package (sqflite for Flutter)
- Shared Preferences package
- Platform-specific build tools (Xcode, Android Studio)

### 16.2 Assumptions
- Users have sufficient device storage for entries
- Users understand basic smartphone interactions
- Target devices support Flutter minimum requirements
- Users accept local-only storage limitation
- Users value privacy over convenience features

---

## 17. Constraints

### 17.1 Technical Constraints
- Must work 100% offline
- No server infrastructure
- Limited to Flutter framework capabilities
- Standard phone screen sizes only (no tablet optimization)

### 17.2 Design Constraints
- Strict monotone (black and white) color palette
- Minimalist aesthetic (no decorative elements)
- Three fonts maximum
- Three font sizes maximum
- Fixed timer durations

### 17.3 Business Constraints
- MVP must be free to use initially
- No ongoing server costs
- Single platform codebase (Flutter)

---

## 18. Appendix

### 18.1 Glossary
- **Entry:** A single journal text record with timestamp
- **Canvas:** The main writing/editing area
- **Bottom Sheet:** Sliding panel from bottom containing settings
- **FAB:** Floating Action Button (+ icon for new entry)
- **Auto-save:** Automatic background saving without user action

### 18.2 References
- Flutter Documentation: https://flutter.dev/docs
- Material Design Guidelines: https://material.io/design
- iOS Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

### 18.3 Document Version History
- v1.0 (Jan 29, 2026): Initial PRD creation

---

## 19. Sign-off

This Product Requirements Document represents the complete specification for Minimal Journal v1.0 MVP. All stakeholders should review and approve before development begins.

**Approvals Required:**
- [ ] Product Owner
- [ ] Engineering Lead
- [ ] Design Lead
- [ ] QA Lead

---

**Document End**

*Total Word Count: 4,247 words*
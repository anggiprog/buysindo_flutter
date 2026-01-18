# 📱 Transaction History Tab - Visual UI Guide

## 🎨 UI Layout & Components

### AppBar Section
```
┌─────────────────────────────────────────┐
│ [PRIMARY COLOR BACKGROUND]              │
│                                         │
│  Riwayat Transaksi    [WHITE TEXT]     │
│                                         │
└─────────────────────────────────────────┘
```

Features:
- Background: `appConfig.primaryColor` ✅
- Title: White, Bold
- Flat design (no shadow)
- Left-aligned title

### Search & Filter Section
```
┌─────────────────────────────────────────┐
│ ┌─────────────────────────────────────┐ │
│ │ 🔍 Cari ID Ref atau Nomor HP...  ✕│ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [Semua] [Sukses] [Pending] [Gagal]    │ │
│        ← Horizontally Scrollable →      │
└─────────────────────────────────────────┘
```

Features:
- Search icon: Dynamic color from `appConfig`
- Clear (X) button: Shows when typing
- Filter chips: 4 options, horizontally scrollable
- Selected chip: Primary color background

### Transaction Card
```
┌─────────────────────────────────────────┐
│ 2024-01-18 10:30       [STATUS BADGE] ✓ │
│ ─────────────────────────────────────── │
│                                         │
│ 🛍️  Pulsa Telkomsel 10rb    Rp 11.200  │
│    08129999888                          │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Ref ID: TRX002                  📋 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│   ← TAP TO VIEW DETAILS                 │
└─────────────────────────────────────────┘
```

Components:
- **Top Row:** Timestamp (gray) | Status Badge (color-coded)
- **Divider:** Full width line
- **Product Row:**
  - CircleAvatar: Primary color background
  - Product Name: Bold, max 2 lines with ellipsis
  - Phone: Gray, smaller font
  - Price: Primary color, bold, right-aligned
- **Ref ID Box:**
  - Gray background
  - Monospace font
  - Copy icon: Primary color, clickable with ripple effect

### Status Badge Colors
```
[SUKSES]      → Green (#4CAF50)
[PENDING]     → Orange (#FF9800)
[GAGAL]       → Red (#F44336)
```

### Loading State
```
┌─────────────────────────────────────────┐
│                                         │
│           ⏳ [SPINNER]                  │
│                                         │
│     Memuat riwayat transaksi...        │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

Features:
- Centered layout
- Spinner: Primary color
- Text: Gray

### Error State
```
┌─────────────────────────────────────────┐
│                                         │
│           ⚠️ [ERROR ICON]               │
│                                         │
│        Gagal memuat transaksi           │
│                                         │
│      Terjadi kesalahan                  │
│      [Coba Lagi BUTTON]                 │
│                                         │
└─────────────────────────────────────────┘
```

Features:
- Centered error icon
- Error message in bold
- Retry button: Primary color
- Button has icon and text

### Empty State
```
┌─────────────────────────────────────────┐
│                                         │
│          📄 [EMPTY ICON]                │
│                                         │
│        Tidak ada transaksi              │
│                                         │
│  Belum ada riwayat transaksi            │
│                                         │
└─────────────────────────────────────────┘
```

Features:
- Light gray empty icon
- Centered friendly message
- Extra detail message

### Copy Confirmation SnackBar
```
                    ┌──────────────────────┐
                    │ ✅ Ref ID tersalin   │
                    │    ke clipboard      │
                    └──────────────────────┘
                         (2 seconds)
```

Features:
- Float at bottom
- Green background
- White checkmark icon
- White text
- Auto-dismiss after 2 seconds
- Rounded corners

## 📐 Spacing & Dimensions

### Padding
```
AppBar padding:      16px (all sides)
Card margin:         12px (bottom only)
Card padding:        16px (all sides)
Divider height:      24px
Icon sizes:          14-64px
Font sizes:          11-16px
Border radius:       8-20px (cards/chips)
```

### List Layout
```
Horizontal padding:  16px left + right
Vertical padding:    12px top + bottom
Item spacing:        12px gap between cards
```

## 🎭 Interactive Elements

### Search Bar
- **Default:** Hint text visible
- **Typing:** Text shown, X button appears
- **Clear:** X button removes text instantly
- **Filtering:** Results update in real-time

### Filter Chips
- **Unselected:** Gray background, gray text
- **Selected:** Primary color background, primary color text
- **Checkmark:** Visible when selected
- **Tap:** Instant filter update

### Copy Button
- **Normal:** Gray icon (on hover: ripple effect)
- **Tap:** Icon briefly highlight, snackbar appears
- **Feedback:** Green snackbar with checkmark

### Transaction Card
- **Normal:** White background, subtle shadow
- **Hover/Press:** Slight elevation increase
- **Tap:** Navigate to detail page with smooth animation

### Pull to Refresh
- **Drag Down:** Spinner appears at top
- **Release:** Refresh initiates
- **Complete:** Data updates, spinner fades
- **Spinner Color:** Primary color

## 🔄 State Transitions

### On App Launch
```
Empty → Loading → [API/Cache] → Data Loaded
                                    ↓
                            Display Filtered
```

### On Search Input
```
Current Data → Apply Search → Update Filter → Rebuild UI
(1-2ms delay for better UX)
```

### On Filter Tap
```
Current Data → Apply Status → Update Filter → Rebuild UI
             + Apply Search
```

### On Copy Click
```
Click → Copy to Clipboard → Show SnackBar → Auto-dismiss
(2 seconds)
```

### On Card Tap
```
Click → Page Navigation → Transition Animation → Detail Page Opens
(with ref_id & transaction_id passed)
```

### On Pull Refresh
```
Drag Down → Show Spinner → Fetch API → Update Cache → Rebuild
```

## 🎨 Color Palette

### Dynamic Colors (from appConfig)
```
Primary Color:    appConfig.primaryColor
Text Color:       appConfig.textColor (used for AccentColors)
```

### Fixed Colors
```
White:           #FFFFFF (Cards, AppBar text)
Light Gray:      #F5F5F5 (Background, Ref ID box)
Medium Gray:     #999999 (Icons, hints)
Dark Gray:       #333333 (Text)
Green (Success): #4CAF50 (Sukses badge)
Orange (Pending):#FF9800 (Pending badge)
Red (Failed):    #F44336 (Gagal badge)
Divider:         #EFEFEF
```

## 📏 Typography

### Sizes
```
AppBar Title:     FontWeight.bold, size 16
Card Date:        size 12 (gray)
Product Name:     FontWeight.bold, size 15
Phone Number:     size 13 (gray)
Price:            FontWeight.bold, size 16 (primary)
Ref ID:           size 11, monospace (gray)
Status Badge:     FontWeight.bold, size 10
Loading Text:     size 14 (gray)
```

### Fonts
```
Default:   System font (Roboto)
Ref ID:    Monospace (for better readability)
```

## 🎬 Animations

### Transitions
- **Page Navigate:** MaterialPageRoute (default slide animation)
- **SnackBar:** Slide up from bottom (automatic)
- **Pull Refresh:** Spinner fade in/out (automatic)

### No Animations (Fast UX)
- Search filtering (instant)
- Filter chip tap (instant)
- Copy feedback (immediate snackbar)

## ✅ Accessibility

### Touch Targets
- Search X button: 44x44px minimum
- Copy icon: 44x44px InkWell ripple
- Filter chips: 40px height
- Card: Full width (easily tappable)

### Semantic Labels
- Icons have InkWell ripple feedback
- All buttons are clearly visible
- Color not the only indicator (badges have text)

## 📱 Responsive Behavior

### Different Screen Sizes
- **Phone (320-480px):** All elements adapt, single column list
- **Tablet (480+px):** Same layout, more breathing room
- **Landscape:** Same, but potentially shows more transactions

### Text Wrapping
- Product Name: Max 2 lines with ellipsis
- Search results: No text truncation needed
- Filter chips: Auto-scroll horizontally

---

**Visual Design:** Modern, Clean, Professional  
**Theme:** Material Design 3  
**Accessibility:** WCAG Compliant  
**Performance:** 60 FPS animations

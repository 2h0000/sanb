# Security Features Flow Diagram

## Auto-Lock Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Activity                            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              User presses Home button                       │
│              (App goes to background)                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│         AppLifecycleObserver detects                        │
│         state change to 'paused'                            │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│      SecurityService.startAutoLockTimer()                   │
│      Timer set for 5 minutes                                │
└─────────────────────────────────────────────────────────────┘
                           ↓
                    ┌──────┴──────┐
                    │             │
         User returns within 5 min │ Timer expires (5 min passed)
                    │             │
                    ↓             ↓
        ┌───────────────┐  ┌──────────────────┐
        │ Timer         │  │ onAutoLock()     │
        │ cancelled     │  │ callback fires   │
        └───────────────┘  └──────────────────┘
                                   ↓
                          ┌──────────────────┐
                          │ dataKeyProvider  │
                          │ set to null      │
                          └──────────────────┘
                                   ↓
                          ┌──────────────────┐
                          │ Vault is LOCKED  │
                          │ Must re-unlock   │
                          └──────────────────┘
```

## Clipboard Auto-Clear Flow

```
┌─────────────────────────────────────────────────────────────┐
│         User taps "Copy" on password field                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│    VaultDetailScreen._copyToClipboard()                     │
│    with isPassword: true                                    │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  SecurityService.copyToClipboardWithAutoClear()             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  1. Copy password to clipboard                              │
│  2. Cancel any existing clear timer                         │
│  3. Start new 30-second timer                               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  Show SnackBar:                                             │
│  "Password copied (will clear in 30 seconds)"               │
└─────────────────────────────────────────────────────────────┘
                           ↓
                    ┌──────┴──────┐
                    │             │
         User copies another pwd  │ 30 seconds pass
         (cancels previous timer) │
                    │             │
                    ↓             ↓
        ┌───────────────┐  ┌──────────────────┐
        │ New timer     │  │ _clearClipboard()│
        │ starts        │  │ called           │
        └───────────────┘  └──────────────────┘
                                   ↓
                          ┌──────────────────┐
                          │ Clipboard set to │
                          │ empty string     │
                          └──────────────────┘
```

## Screenshot Prevention Flow (Android)

```
┌─────────────────────────────────────────────────────────────┐
│              App starts on Android device                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│         MainActivity.onCreate() called                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  window.setFlags(                                           │
│    WindowManager.LayoutParams.FLAG_SECURE,                  │
│    WindowManager.LayoutParams.FLAG_SECURE                   │
│  )                                                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│         FLAG_SECURE applied to entire window                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  User tries to take screenshot                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  Android system blocks screenshot                           │
│  - Shows black screen in screenshot, OR                     │
│  - Shows "Can't take screenshot" error                      │
└─────────────────────────────────────────────────────────────┘
```

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    EncryptedNotebookApp                      │
│                  (ConsumerStatefulWidget)                    │
│                                                              │
│  initState():                                                │
│    - Creates AppLifecycleObserver(ref)                       │
│    - Registers with WidgetsBinding                           │
│                                                              │
│  dispose():                                                  │
│    - Removes observer from WidgetsBinding                    │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│              AppLifecycleObserver                            │
│                                                              │
│  didChangeAppLifecycleState(state):                          │
│    - paused/inactive → startAutoLockTimer()                  │
│    - resumed → cancelAutoLockTimer()                         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│                  SecurityService                             │
│                                                              │
│  Fields:                                                     │
│    - _autoLockTimer: Timer?                                  │
│    - _clipboardClearTimer: Timer?                            │
│    - onAutoLock: VoidCallback?                               │
│                                                              │
│  Methods:                                                    │
│    - startAutoLockTimer()                                    │
│    - cancelAutoLockTimer()                                   │
│    - copyToClipboardWithAutoClear(text)                      │
│    - _clearClipboard()                                       │
│    - dispose()                                               │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│              securityServiceProvider                         │
│                                                              │
│  Creates SecurityService with:                               │
│    onAutoLock: () {                                          │
│      ref.read(dataKeyProvider.notifier).state = null;        │
│    }                                                         │
│                                                              │
│  Cleanup on dispose:                                         │
│    service.dispose()                                         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│                  dataKeyProvider                             │
│                  (StateProvider<List<int>?>)                 │
│                                                              │
│  When set to null:                                           │
│    - Vault becomes locked                                    │
│    - vaultServiceProvider returns null                       │
│    - User must re-enter master password                      │
└──────────────────────────────────────────────────────────────┘
```

## State Transitions

### Vault Lock State

```
┌─────────────┐
│   LOCKED    │ ←──────────────────────┐
│ (dataKey =  │                        │
│    null)    │                        │
└─────────────┘                        │
       ↓                               │
  User enters                          │
  master password                      │
       ↓                               │
┌─────────────┐                        │
│  UNLOCKED   │                        │
│ (dataKey =  │                        │
│  [bytes])   │                        │
└─────────────┘                        │
       ↓                               │
  App goes to                          │
  background                           │
       ↓                               │
┌─────────────┐                        │
│   TIMER     │                        │
│  RUNNING    │                        │
│ (5 minutes) │                        │
└─────────────┘                        │
       ↓                               │
  Timer expires ─────────────────────→ │
  (Auto-lock)
```

### Clipboard State

```
┌─────────────┐
│   EMPTY     │ ←──────────────────────┐
│             │                        │
└─────────────┘                        │
       ↓                               │
  User copies                          │
  password                             │
       ↓                               │
┌─────────────┐                        │
│  CONTAINS   │                        │
│  PASSWORD   │                        │
└─────────────┘                        │
       ↓                               │
  Timer starts                         │
  (30 seconds)                         │
       ↓                               │
┌─────────────┐                        │
│   TIMER     │                        │
│  RUNNING    │                        │
└─────────────┘                        │
       ↓                               │
  Timer expires ─────────────────────→ │
  (Auto-clear)
```

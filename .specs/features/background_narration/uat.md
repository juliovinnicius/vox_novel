# Milestone 5 UAT — Background Narration

**Status**: Prepared — not yet executed
**Scope**: Everything the suite cannot reach — a real lock screen, a real
Bluetooth headset, a real phone call, a real foreground service.
**Target**: Physical Android device, API 33 or higher (so the notification
permission is actually requested), with at least one installed TTS voice and a
Bluetooth headset available.

## Why these cases and not others

The automated suite covers the state machine: what pauses, what resumes, what
each command does, what every surface publishes. What it cannot cover is whether
Android honours any of it. Each case below fails only for a reason no unit test
could see.

## Setup

- Install the debug APK on the target device.
- Import one PDF with at least two chapters and several paragraphs.
- Record device model, Android version, app commit, and the voice used.
- Start from a fresh install, so UAT-01's permission prompt is genuine.

## Checklist

| ID | Procedure | Expected result | Result / evidence |
| --- | --- | --- | --- |
| UAT-01 | On a fresh install, open a book and press play for the first time. | The notification permission is requested **at that moment**, not at app launch. Granting it makes the media notification appear. | ☐ Pass ☐ Fail — |
| UAT-02 | Deny the permission, then press play again. | Narration plays anyway. The app states once that controls outside it are unavailable, and does not repeat that message on later blocks. | ☐ Pass ☐ Fail — |
| UAT-03 | With narration playing, press the power button to lock the screen. Wait through two paragraphs. | Speech continues without a gap. The lock screen shows the book title, the chapter beneath it, and previous / pause / next. | ☐ Pass ☐ Fail — |
| UAT-04 | With narration playing, go to the home screen and open another app. | Speech continues. The notification remains in the shade. | ☐ Pass ☐ Fail — |
| UAT-05 | With narration playing, open recents and swipe the app away. | Speech continues for at least two more paragraphs. *(Measured on a Xiaomi 2210129SG / Android 15 during the T2 spike: four paragraphs over 19s.)* | ☐ Pass ☐ Fail — |
| UAT-06 | From the lock screen, press pause, then play. | Speech stops on the pause and resumes from the **start of the same paragraph**, not mid-sentence. | ☐ Pass ☐ Fail — |
| UAT-07 | From the lock screen, press next once, then previous once. | Each press moves exactly **one paragraph**, not one chapter, and the destination paragraph starts from its beginning. | ☐ Pass ☐ Fail — |
| UAT-08 | Pair a Bluetooth headset. With narration playing, press its play/pause button, then its next-track button. | The headset controls act exactly like the notification's. *(This is the case `androidForceEnableMediaButtons()` exists for; without it the notification still looks functional while every headset press is dropped.)* | ☐ Pass ☐ Fail — |
| UAT-09 | With narration playing, call the device from another phone. Let it ring, then decline. | Speech stops for the call and **resumes on its own** afterwards, from the start of the interrupted paragraph. | ☐ Pass ☐ Fail — |
| UAT-10 | With narration playing, open a music app and press play there. | Narration pauses and **stays paused** after the other audio stops. Its notification remains, so resuming is one tap. | ☐ Pass ☐ Fail — |
| UAT-11 | Play through wired or Bluetooth headphones, then disconnect them. | Narration pauses. Nothing plays from the device speaker. Reconnecting does not resume on its own. | ☐ Pass ☐ Fail — |
| UAT-12 | With narration playing in the background, reopen the app. | Speech does not gap or restart. The in-app player shows playing, on the same paragraph being spoken, and the reader is scrolled to and highlighting that paragraph. | ☐ Pass ☐ Fail — |
| UAT-12b | While narration is playing, go back to the library and re-open **the same** book. | Speech does not stop, restart, or skip. The reader opens on the paragraph being spoken. *(This is the path that broke in verification: the reader loads on every mount, and without a same-book guard re-entry killed the live session.)* | ☐ Pass ☐ Fail — |
| UAT-13 | While narrating book A, return to the library and open book B. | Book A's narration ends rather than continuing underneath. Only one notification exists at any moment. | ☐ Pass ☐ Fail — |
| UAT-14 | Let narration reach the final paragraph of the book. | Speech stops, the book is marked completed, the notification disappears, and pressing next does not wrap to the beginning. | ☐ Pass ☐ Fail — |
| UAT-15 | Pause narration and try to swipe the notification away. Then resume and try again while it is playing. | Dismissible while paused; not dismissible while playing. Dismissing it while paused ends the session. | ☐ Pass ☐ Fail — |
| UAT-16 | Pause narration, leave the device untouched for 30 minutes, then look at the lock screen. | **Known risk, measured as uncertain**: the design records that a long-paused session may be reclaimed by the system, losing the one-tap resume. Record what actually happens — controls still present, or gone. | ☐ Pass ☐ Fail — |
| UAT-17 | With narration playing, delete the book being narrated from the library. | Speech stops immediately and the notification disappears. No control survives for a book that no longer exists. | ☐ Pass ☐ Fail — |
| UAT-18 | Narrate a web book whose chapters are still downloading, until it reaches the last downloaded paragraph. | Narration reports waiting for the next chapter rather than ending the book, and the notification does not claim the book finished. | ☐ Pass ☐ Fail — |
| UAT-19 | With TalkBack enabled, traverse the in-app player after returning from the background. | Portuguese labels, correct selected/disabled state, and play/pause, previous and next all reachable and usable. | ☐ Pass ☐ Fail — |

## Recording the run

- Device: ______________  Android: ______  App commit: ______________
- Voice used: ______________
- Any case that fails: capture the notification, the lock screen, and
  `adb logcat` around the moment of failure.

## Cases deliberately not here

- Everything the suite already discriminates: pause/resume rules, one-block
  navigation, focus mapping, degradation messages, package confinement. Repeating
  them by hand would cost device time without adding evidence.
- The sleep timer: Milestone 6, out of this feature's scope.

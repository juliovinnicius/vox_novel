# Combined Milestone 3–4 UAT

**Status**: Prepared — not yet executed
**Scope**: Visual reader continuity plus foreground on-device narration
**Target**: Physical Android device with at least two installed voices

## Setup

- Install the current debug APK on the target device.
- Import one selectable-text PDF with at least two chapters and several paragraphs.
- Confirm a second PDF is available for PDF/text continuity checks.
- Record device model, Android version, installed app version/commit, and voices used.

## Checklist

| ID | Procedure | Expected result | Result / evidence |
| --- | --- | --- | --- |
| UAT-01 | Open the processed book in text mode, select a paragraph, change chapter, close, and reopen. | Text content, chapter navigation, and durable visual position remain correct. | ☐ Pass ☐ Fail — |
| UAT-02 | Switch from text to the original PDF and back on both books. | PDF opens at the mapped page and text returns to the corresponding readable block without losing reader continuity. | ☐ Pass ☐ Fail — |
| UAT-03 | Exercise light, sepia, and dark themes; change font family, size, and line spacing; reopen the app. | Every visual setting applies immediately, remains legible, and restores exactly after restart. | ☐ Pass ☐ Fail — |
| UAT-04 | Open narration settings, select another installed voice, preview it, enable the per-book scope, and reopen settings. | Preview uses the exact selected voice phrase; selection and book scope remain exact without changing narration progress. | ☐ Pass ☐ Fail — |
| UAT-05 | Set speed to 0.5×, step upward by 0.1×, then set 2.0×. | Speech changes at each step; decrease is disabled at 0.5× and increase is disabled at 2.0×. | ☐ Pass ☐ Fail — |
| UAT-06 | Tap a paragraph and press play, pause, then play again. | The tapped paragraph is the origin; pause stops foreground speech; resume restarts that complete paragraph from its beginning. | ☐ Pass ☐ Fail — |
| UAT-07 | Let narration complete multiple paragraphs and cross a chapter boundary. | Blocks play once in source order, empty chapters are skipped, and the next chapter begins automatically without wrap. | ☐ Pass ☐ Fail — |
| UAT-08 | Observe the text reader during play and automatic/manual next/previous actions. | The exact narrated paragraph is highlighted and brought into view within 500 ms without persisting a new visual position. | ☐ Pass ☐ Fail — |
| UAT-09 | Pause on a non-final paragraph, terminate the app, relaunch, and reopen the book. | Exact voice, speed, scope, chapter, and block restore without autoplay; pressing play restarts that block. | ☐ Pass ☐ Fail — |
| UAT-10 | While playing, background the app and then return. | The player leaves `playing` immediately, foreground speech stops, progress is saved, and narration remains paused with no automatic resume. | ☐ Pass ☐ Fail — |
| UAT-11 | Complete the final block, press next, close, and reopen. | State remains completed on the final block, next is disabled, no additional speech occurs, and the book does not wrap. | ☐ Pass ☐ Fail — |
| UAT-12 | With TalkBack enabled, traverse player and narration-settings controls. | Portuguese labels, selected/disabled state, logical order, and touch targets are usable for play/pause, previous/next, voice, preview, speed, scope, and retry. | ☐ Pass ☐ Fail — |

## Completion record

- Tester:
- Device / Android:
- Commit / APK:
- Started (UTC):
- Completed (UTC):
- Overall: ☐ Pass ☐ Fail
- Failed IDs and notes:

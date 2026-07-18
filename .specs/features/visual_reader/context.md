# Visual Reader Context

**Gathered:** 2026-07-18
**Spec:** `.specs/features/visual_reader/spec.md`
**Status:** Ready for confirmation

---

## Feature Boundary

Milestone 3 opens a processed book in an offline visual reader, supports
reformatted text and the original PDF, chapter navigation, visual themes,
typography controls, paragraph selection/highlight, and restoration of the
last visual position. Narration, audio controls, bookmarks, OCR, and narration
progress remain outside this milestone.

---

## Implementation Decisions

### Initial mode and mode switching

- A book opens in reformatted text mode unless that book has a saved visual
  mode from an earlier reading session.
- The app bar exposes one accessible control for switching between text and PDF.
- Switching to PDF opens the page associated with the selected text block or
  chapter; switching to text selects the chapter/block associated with the
  visible PDF page.

### Chapter navigation

- Chapters appear in an end drawer so the reading surface remains uncluttered.
- The current chapter is identified in the drawer.
- Previous/next chapter actions are available in text mode and use source order.
- Selecting a chapter closes the drawer and moves to its first block, or to the
  empty chapter heading when it contains no blocks.

### Themes and typography

- Initial themes are light, sepia, and dark.
- Global defaults are system sans-serif, 18 logical pixels, 1.5 line height,
  and light theme.
- Font family choices are system sans-serif and system serif.
- Font size is bounded from 14 to 32 in increments of 2.
- Line height choices are 1.2, 1.5, 1.8, and 2.0.
- Typography and theme preferences apply globally and persist across restarts.

### Paragraph highlight and position

- One narration block is the selected paragraph; it receives a clear visual
  highlight without changing its text.
- Tapping a paragraph selects it and persists that visual position for future
  narration integration.
- The reader restores the last selected block in text mode or visible page in
  PDF mode per book.
- Visual-position persistence is separate from Milestone 4 narration progress.

### Agent's Discretion

- Exact spacing, colors, animation durations, icons, and responsive breakpoints,
  provided contrast, semantics, and the decisions above remain satisfied.
- Internal debounce/serialization details for position persistence.

### Declined / Undiscussed Gray Areas → Assumptions

The user delegated all visual-reader gray areas. Defaults above are recorded as
explicit assumptions in the specification with rationale.

---

## Specific References

No external product reference was requested. Follow the application's existing
Material design language and accessibility conventions.

---

## Deferred Ideas

- TTS playback and automatic narrated-block advancement: Milestone 4.
- Keep-screen-awake behavior: deferred until playback/lifecycle integration.
- Chapter editing, bookmarks, and configurable reprocessing: Milestone 6.


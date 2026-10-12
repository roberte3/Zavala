# Zavala Behavior Inventory

The source of truth for what the behavior suite protects. See `SPEC.md` for the rules.

- **ID** never changes and is never reused. The test's display name starts with it.
- **Behavior** is one sentence about what the user sees, not about code.
- **Layer:** L1 model/command (`VinOutlineKitTests`), L2 editor (`ZavalaTests`), L3 smoke (`ZavalaUITests`).
- **Test:** `Suite/function()`, as `-only-testing` takes it.
- **Status:** `uncovered`, `covered · verified <date>` (its mutation in `mutations/<ID>.patch` failed the test), or `diverged → DV-nnn`. A `· known bug ZB-nnn` suffix means part of the test is wrapped in `withKnownIssue`.

Tools: `tools/behavior-report.sh` (what's broken), `tools/mutate.sh <ID>` (prove the test can fail). Before writing tests, read `HARNESS-NOTES.md`.

---

# P1 — Outline editing and UI core

Unless noted, undo restores the outline exactly and redo re-applies the edit; every edit test checks both.

Drafted from reading Zavala's code. A **(?)** marks a sentence not yet confirmed against Zavala; covering it either confirms it or rewrites it to match what Zavala does.

## ED: Editing — Indent / Outdent

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-010 | Indenting a row (Tab) makes it the last child of the row above it, bringing its children along | L1 | IndentBehaviors/ed010() | covered · verified 2026-10-09 |
| ED-011 | Indenting the first row at its level does nothing, and Indent is unavailable for it | L1 | IndentBehaviors/ed011() | covered · verified 2026-10-09 |
| ED-012 | After Tab, the cursor stays at the same character position in the moved row | L2 | IndentEditorBehaviors/ed012() | covered · verified 2026-10-09 |
| ED-013 | Indenting several adjacent rows makes them all children of the row above, in their original order | L1 | IndentBehaviors/ed013() | covered · verified 2026-10-09 |
| ED-014 | Indenting a row under a collapsed row expands that row so the moved row stays visible | L1 | IndentBehaviors/ed014() | covered · verified 2026-10-09 |
| ED-015 | Outdenting a row (Shift-Tab) moves it, with its children, to just after its parent; rows below it stay under the old parent | L1 | IndentBehaviors/ed015() | covered · verified 2026-10-09 |
| ED-016 | Outdenting a top-level row does nothing, and Outdent is unavailable for it | L1 | IndentBehaviors/ed016() | covered · verified 2026-10-09 |
| ED-017 | Outdenting several sibling rows keeps their order, placed just after their old parent | L1 | IndentBehaviors/ed017() | covered · verified 2026-10-09 |
| ED-018 | Outdenting a row together with one of its own children moves only the row; the child stays inside it | L1 | IndentBehaviors/ed018() | covered · verified 2026-10-09 |
| ED-019 | Indenting an incomplete row under a completed row marks that row incomplete | L1 | IndentBehaviors/ed019() | covered · verified 2026-10-09 · known bug ZB-001 |
| ED-020 | Indenting a completed row under an incomplete row whose children are then all complete marks that row complete | L1 | IndentBehaviors/ed020() | covered · verified 2026-10-09 · known bug ZB-001 |
| ED-021 | Outdenting the last incomplete child of a row whose other children are complete marks that row complete | L1 | IndentBehaviors/ed021() | covered · verified 2026-10-09 |
| ED-022 | Indenting while editing a row keeps its new text; undo restores both the position and the earlier text | L1 | IndentBehaviors/ed022() | covered · verified 2026-10-09 |

## ED: Editing — Creating rows

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-030 | Return at the end of a row creates an empty row just below it at the same level, and the cursor moves into it | L2 | CreateRowEditorBehaviors/ed030() | covered · verified 2026-10-09 |
| ED-031 | Return at the end of a row whose children are showing creates the new row as its first child | L1 | CreateRowBehaviors/ed031() | covered · verified 2026-10-09 |
| ED-032 | Return at the end of a collapsed row with children creates the new row as its next sibling, after the hidden children | L1 | CreateRowBehaviors/ed032() | covered · verified 2026-10-09 |
| ED-033 | With the "create rows at same level" setting, Return at the end of a row with showing children creates a sibling instead of a first child | L2 | CreateRowEditorBehaviors/ed033() | covered · verified 2026-10-09 |
| ED-034 | Return at the start of a row that has text creates an empty row above it; the cursor stays in the original row | L2 | CreateRowEditorBehaviors/ed034() | covered · verified 2026-10-09 |
| ED-035 | Return in an empty row that is the last child of its parent outdents it instead of creating a row | L2 | CreateRowEditorBehaviors/ed035() | covered · verified 2026-10-09 · known bug ZB-002 |
| ED-036 | Return in an empty row that is not the last child (or is top-level) creates an empty row above it | L2 | CreateRowEditorBehaviors/ed036() | covered · verified 2026-10-09 |
| ED-037 | Shift-Return creates an empty row above the current row and moves the cursor into it | L2 | CreateRowEditorBehaviors/ed037() | covered · verified 2026-10-09 |
| ED-038 | Add Row Below (Ctrl-Return) creates an empty row below the current row and Add Row Above (Shift-Return) one above; both move the cursor into it | L2 | CreateRowEditorBehaviors/ed038() | covered · verified 2026-10-09 |
| ED-039 | Add Row Inside (Cmd-}) creates an empty first child of the current row, expanding it if collapsed, and moves the cursor into it | L2 | CreateRowEditorBehaviors/ed039() | covered · verified 2026-10-09 |
| ED-040 | Add Row Outside (Cmd-{) creates an empty row just after the current row's parent, and is unavailable for top-level rows | L1 | CreateRowBehaviors/ed040() | covered · verified 2026-10-09 |
| ED-041 | Creating a row inside a completed row marks that row incomplete | L1 | CreateRowBehaviors/ed041() | covered · verified 2026-10-09 |
| ED-042 | Text typed into the current row before creating a new row is kept; undo removes only the new row and leaves the text | L1 | CreateRowBehaviors/ed042() | covered · verified 2026-10-09 |
| ED-043 | While focused on a row, Return at the end of the focused row creates its first child | L1 | CreateRowBehaviors/ed043() | covered · verified 2026-10-09 |

## ED: Editing — Split and join

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-050 | Return in the middle of a row's text splits it: text after the cursor moves to a new row just below, and the cursor goes to the start of that row | L2 | SplitJoinEditorBehaviors/ed050() | covered · verified 2026-10-09 |
| ED-051 | Splitting a row whose children are showing puts the second half as its first child | L1 | SplitJoinBehaviors/ed051() | covered · verified 2026-10-09 |
| ED-052 | Splitting keeps bold, italic, and links on each half of the text | L1 | SplitJoinBehaviors/ed052() | covered · verified 2026-10-09 |
| ED-053 | Shift-Option-Return splits at the cursor like Return; at the very start of the row it creates an empty row above without moving the cursor | L2 | SplitJoinEditorBehaviors/ed053() | covered · verified 2026-10-09 |
| ED-054 | Delete at the start of a row joins its text onto the end of the row above, when that row is its previous sibling | L2 | SplitJoinEditorBehaviors/ed054() | covered · verified 2026-10-09 |
| ED-055 | Delete at the start of a row does nothing when the row above is not its sibling (e.g. it is the parent) | L2 | SplitJoinEditorBehaviors/ed055() | covered · verified 2026-10-09 |
| ED-056 | Rows with children are never joined into the row above; Delete at their start does nothing | L2 | SplitJoinEditorBehaviors/ed056() | covered · verified 2026-10-09 · known bug ZB-003 |
| ED-057 | After a join, the cursor sits at the join point | L2 | SplitJoinEditorBehaviors/ed057() | covered · verified 2026-10-09 |
| ED-058 | Undo of a split restores the single row and its text; undo of a join restores both rows | L1 | SplitJoinBehaviors/ed058() | covered · verified 2026-10-09 |
| ED-059 | Joining two rows keeps both notes: the lower row's note follows the upper row's | L1 | SplitJoinBehaviors/ed059() | covered · verified 2026-10-09 · known bug ZB-004 |

## ED: Editing — Deleting rows

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-070 | Delete in an empty row without children deletes the row and puts the cursor at the end of the row above | L2 | DeleteRowEditorBehaviors/ed070() | covered · verified 2026-10-09 |
| ED-071 | Delete in an empty row that has children does nothing | L2 | DeleteRowEditorBehaviors/ed071() | covered · verified 2026-10-09 |
| ED-072 | Delete Rows (Shift-Cmd-Delete) deletes the selected rows together with all their children | L2 | DeleteRowEditorBehaviors/ed072() | covered · verified 2026-10-09 |
| ED-073 | Deleting the last incomplete child of a row whose other children are complete marks that row complete | L1 | DeleteRowBehaviors/ed073() | covered · verified 2026-10-09 |
| ED-074 | Deleting rows in row-selection mode selects the row now in the first deleted row's place, or the last row if none | L2 | DeleteRowEditorBehaviors/ed074() | covered · verified 2026-10-09 · known bug ZB-007 |
| ED-075 | Delete Completed Rows (Cmd-D) deletes every completed row in the outline, with their children, after a confirmation unless confirmation was turned off | L2 | DeleteRowEditorBehaviors/ed075() | covered · verified 2026-10-09 · known bug ZB-006 |
| ED-076 | Undo of a delete restores the rows, with children, in their original positions | L1 | DeleteRowBehaviors/ed076() | covered · verified 2026-10-09 · known bug ZB-005 |

## ED: Editing — Moving rows up and down

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-090 | Move Up (Ctrl-Cmd-↑) swaps a row, with its children, with the sibling above it | L1 | MoveRowBehaviors/ed090() | covered · verified 2026-10-09 |
| ED-091 | Move Down (Ctrl-Cmd-↓) swaps a row, with its children, with the sibling below it | L1 | MoveRowBehaviors/ed091() | covered · verified 2026-10-09 |
| ED-092 | Move Up is unavailable for a first child and Move Down for a last child; rows never move to another parent this way | L1 | MoveRowBehaviors/ed092() | covered · verified 2026-10-09 |
| ED-093 | Moving several adjacent siblings up or down moves them together, keeping their order | L1 | MoveRowBehaviors/ed093() | covered · verified 2026-10-09 |
| ED-094 | Move Up/Down is unavailable when the selected rows have different parents | L1 | MoveRowBehaviors/ed094() | covered · verified 2026-10-09 |
| ED-095 | After Move Up/Down the cursor stays at the same position in the moved row | L2 | MoveRowEditorBehaviors/ed095() | covered · verified 2026-10-09 |

## ED: Editing — Collapse and expand

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-110 | Collapse (Cmd-0) hides a row's descendants; Expand (Cmd-9) shows them again with their own collapse state intact | L1 | CollapseBehaviors/ed110() | covered · verified 2026-10-09 |
| ED-111 | Collapse and Expand are unavailable for rows without children | L1 | CollapseBehaviors/ed111() | covered · verified 2026-10-09 |
| ED-112 | Collapse All in Row (Opt-Cmd-0) collapses the row and every descendant with children; Expand All in Row (Opt-Cmd-9) expands them all | L1 | CollapseBehaviors/ed112() | covered · verified 2026-10-09 |
| ED-113 | Collapse All in Outline (Ctrl-Cmd-0) and Expand All in Outline (Ctrl-Cmd-9) apply to every row with children | L1 | CollapseBehaviors/ed113() | covered · verified 2026-10-09 |
| ED-114 | Collapse Parent Row (Ctrl-Opt-Cmd-0) collapses the parent of the current row | L2 | CollapseEditorBehaviors/ed114() | covered · verified 2026-10-09 |
| ED-115 | Clicking a row's disclosure triangle toggles it; Option-click applies to all its descendants too | L2 | CollapseEditorBehaviors/ed115() | covered · verified 2026-10-09 |
| ED-116 | Collapse and expand are undoable | L1 | CollapseBehaviors/ed116() | covered · verified 2026-10-09 |
| ED-117 | Collapsing a row while the cursor is in one of its descendants moves the cursor to the end of the collapsed row | L2 | CollapseEditorBehaviors/ed117() | covered · verified 2026-10-09 · known bug ZB-008 |

## ED: Editing — Completing rows

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-130 | Complete (Cmd-Return) marks the current row complete; pressing it again marks it incomplete | L2 | CompleteEditorBehaviors/ed130() | covered · verified 2026-10-09 |
| ED-131 | Completing a row doesn't change its children's completion | L1 | CompleteBehaviors/ed131() | covered · verified 2026-10-09 |
| ED-132 | Completing the last incomplete child of a row marks that row complete too | L1 | CompleteBehaviors/ed132() | covered · verified 2026-10-09 |
| ED-133 | Marking a child incomplete marks its completed parent incomplete too | L1 | CompleteBehaviors/ed133() | covered · verified 2026-10-09 |
| ED-134 | With several rows selected, Complete marks them all complete if any is incomplete; otherwise it marks them all incomplete | L2 | CompleteEditorBehaviors/ed134() | covered · verified 2026-10-09 · known bug ZB-009 |
| ED-135 | With completed rows hidden, completing the current row hides it and moves the cursor to the row above | L2 | CompleteEditorBehaviors/ed135() | covered · verified 2026-10-09 |
| ED-136 | With the filter on, completed rows are hidden together with their children; turning the filter off shows them again | L1 | CompleteBehaviors/ed136() | covered · verified 2026-10-09 |
| ED-137 | Turn Filter On (Shift-Cmd-H) switches the Hide Completed and Hide Notes choices on and off together, without forgetting which ones were chosen | L1 | CompleteBehaviors/ed137() | covered · verified 2026-10-09 |

## ED: Editing — Notes and in-row text

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-150 | Add Note (Ctrl--) gives the current row an empty note and moves the cursor into it | L2 | NoteEditorBehaviors/ed150() | covered · verified 2026-10-09 |
| ED-151 | Ctrl-- on a row that already has a note moves the cursor between its topic and its note | L2 | NoteEditorBehaviors/ed151() | covered · verified 2026-10-09 |
| ED-152 | Delete Note (Ctrl-Shift--) removes the note from the selected rows; undo brings the text back | L1 | NoteBehaviors/ed152() | covered · verified 2026-10-09 |
| ED-153 | Delete in an empty note removes the note and moves the cursor back to the end of the topic | L2 | NoteEditorBehaviors/ed153() | covered · verified 2026-10-09 |
| ED-154 | Option-Return in a topic inserts a line break inside the row instead of creating a row | L2 | NoteEditorBehaviors/ed154() | covered · verified 2026-10-09 |
| ED-155 | Option-Tab inserts a tab character instead of indenting | L2 | NoteEditorBehaviors/ed155() | covered · verified 2026-10-09 |
| ED-156 | Hide Notes hides note text in the editor without deleting it | L2 | NoteEditorBehaviors/ed156() | covered · verified 2026-10-09 |

## ED: Editing — Cut, copy, paste, duplicate

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-170 | Copying selected rows copies them with all their children, notes, and completion | L2 | ClipboardEditorBehaviors/ed170() | covered · verified 2026-10-09 |
| ED-171 | Cutting selected rows removes them (with children) and puts them on the clipboard; undo restores them | L2 | ClipboardEditorBehaviors/ed171() | covered · verified 2026-10-09 · known bug ZB-011 |
| ED-172 | Pasting rows inserts them after the current row at the same level, or as first children when its children are showing | L1 | ClipboardBehaviors/ed172() | covered · verified 2026-10-09 |
| ED-173 | Pasting plain text with several lines while editing a row's text inserts it as text in that row, not as new rows | L2 | ClipboardEditorBehaviors/ed173() | covered · verified 2026-10-09 |
| ED-174 | Duplicate Rows (Ctrl-Cmd-R) inserts a copy of the selected rows, with children, just after the last of them | L1 | ClipboardBehaviors/ed174() | covered · verified 2026-10-09 · known bug ZB-010 |
| ED-175 | Pasted and duplicated rows are new rows; changing them doesn't change the originals | L1 | ClipboardBehaviors/ed175() | covered · verified 2026-10-09 |

## ED: Editing — Drag and drop

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-190 | Dragging rows between two rows moves them, with children, to that position | L1 | DropBehaviors/ed190() | covered · verified 2026-10-09 |
| ED-191 | Dropping rows onto a row makes them its first children | L1 | DropBehaviors/ed191() | covered · verified 2026-10-09 |
| ED-192 | Dropping rows onto themselves or their own descendants does nothing | L1 | DropBehaviors/ed192() | covered · verified 2026-10-09 |
| ED-193 | Dropping rows from another outline copies them into this outline; the source outline is unchanged | L1 | DropBehaviors/ed193() | covered · verified 2026-10-09 |
| ED-194 | Undo of a drop restores both the source and destination positions | L1 | DropBehaviors/ed194() | covered · verified 2026-10-09 |

Drag and drop is tested at the command level: a test can't perform a real drag, so each test runs the command the editor's drop delegate runs, with the destination the delegate computes. Open question: dragging a row *down* among its own siblings may land one place too far, because the delegate computes the index before the dragged row is removed (`Outline.moveRows` doesn't adjust it). That depends on UIKit's drag layout, so it needs a real drag (by hand, or an L3 flow in Task 19).

## ED: Editing — Group and sort

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-210 | Group Rows (Opt-Cmd-G) puts the selected adjacent siblings under a new empty row inserted where the first one was, and moves the cursor into it | L2 | GroupSortEditorBehaviors/ed210() | covered · verified 2026-10-09 · cursor on Mac only; iPad open (see tasks/plan.md "Outstanding") |
| ED-211 | Group Rows is unavailable when the selected rows aren't adjacent siblings | L1 | GroupSortBehaviors/ed211() | covered · verified 2026-10-09 |
| ED-212 | Sort Rows (Opt-Cmd-S) sorts the selected adjacent siblings alphabetically, ignoring case; children move with their rows | L1 | GroupSortBehaviors/ed212() | covered · verified 2026-10-09 |
| ED-213 | Sort Rows is unavailable for a single row or rows that aren't adjacent siblings | L1 | GroupSortBehaviors/ed213() | covered · verified 2026-10-09 |
| ED-214 | Undo of group or sort restores the original structure and order | L1 | GroupSortBehaviors/ed214() | covered · verified 2026-10-09 |

## ED: Editing — Keyboard navigation, selection, and focus

The arrow keys check whether the cursor is on the row's top or bottom line in the hardware-key path (`pressesBegan`), which a test can't drive (no `UIPress` can be built). ED-230, ED-231, ED-233, and ED-234 therefore drive Ctrl-N/Ctrl-P, which reach the same move, so the arrow-to-edge mapping is unverified until an L3 flow covers it (Task 19).

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-230 | Down arrow on a row's last line moves the cursor to the next visible row, keeping roughly the same horizontal position | L2 | KeyboardNavigationEditorBehaviors/ed230() | covered · verified 2026-10-09 |
| ED-231 | Up arrow on a row's first line moves the cursor to the previous visible row, keeping roughly the same horizontal position | L2 | KeyboardNavigationEditorBehaviors/ed231() | covered · verified 2026-10-09 |
| ED-232 | Ctrl-P and Ctrl-N move the cursor up and down a row, like the arrows | L2 | KeyboardNavigationEditorBehaviors/ed232() | covered · verified 2026-10-09 |
| ED-233 | Up from the first row moves the cursor to the tags field | L2 | KeyboardNavigationEditorBehaviors/ed233() | covered · verified 2026-10-09 |
| ED-234 | Down from the last row moves the cursor to the end of that row | L2 | KeyboardNavigationEditorBehaviors/ed234() | covered · verified 2026-10-09 |
| ED-235 | Navigation skips rows hidden inside collapsed rows | L2 | KeyboardNavigationEditorBehaviors/ed235() | covered · verified 2026-10-09 |
| ED-236 | Esc while editing a row selects that row (row-selection mode); Esc again returns the cursor to its text | L2 | KeyboardNavigationEditorBehaviors/ed236() | covered · verified 2026-10-09 |
| ED-237 | Tab and Shift-Tab are only offered while editing a row's topic, not its note or the title | L2 | KeyboardNavigationEditorBehaviors/ed237() | covered · verified 2026-10-09 |
| ED-238 | Focus In (Opt-Cmd-→) shows only the current row and its descendants; Focus Out (Opt-Cmd-←) shows the whole outline again | L2 | KeyboardNavigationEditorBehaviors/ed238() | covered · verified 2026-10-09 |
| ED-239 | Focus Out is unavailable when not focused | L2 | KeyboardNavigationEditorBehaviors/ed239() | covered · verified 2026-10-09 |

## ED: Editing — Undo across several edits

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-250 | A sequence of mixed edits (create, type, indent, move, complete, delete) undoes step by step back to the exact original outline | L1 | UndoSequenceBehaviors/ed250() | covered · verified 2026-10-09 |
| ED-251 | After undoing a sequence, redo re-applies each step in order, ending at the exact edited outline | L1 | UndoSequenceBehaviors/ed251() | covered · verified 2026-10-09 |
| ED-252 | Typing in a row and then a structural edit undo separately: the first undo reverts the structure, the next reverts the typing | L2 | UndoSequenceEditorBehaviors/ed252() | covered · verified 2026-10-10 |

## ED: Editing — Text formatting

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-270 | Bold (Cmd-B) toggles bold on the selected text in a topic or note | L2 | FormatEditorBehaviors/ed270() | covered · verified 2026-10-09 |
| ED-271 | Italic (Cmd-I) toggles italic on the selected text | L2 | FormatEditorBehaviors/ed271() | covered · verified 2026-10-09 |
| ED-272 | Code (Ctrl-Opt-Cmd-C) toggles inline code style on the selected text | L2 | FormatEditorBehaviors/ed272() | covered · verified 2026-10-09 |
| ED-273 | Highlight (Ctrl-Opt-Cmd-H) toggles highlighting on the selected text | L2 | FormatEditorBehaviors/ed273() | covered · verified 2026-10-09 |
| ED-274 | With no text selected, a formatting command applies to the text typed next | L2 | FormatEditorBehaviors/ed274() | covered · verified 2026-10-09 |
| ED-275 | Formatting stays with its text when the row is moved, copied, split, or joined | L1 | FormatBehaviors/ed275() | covered · verified 2026-10-09 |
| ED-276 | Formatting changes are undoable | L2 | FormatEditorBehaviors/ed276() | covered · verified 2026-10-09 |

## ED: Editing — Title and tags field

| ID | Behavior | Layer | Test | Status |
|---|---|---|---|---|
| ED-290 | Typing in the title changes the outline's title (saved once typing pauses); Undo and Redo change it back and forth | L2 | TitleTagsEditorBehaviors/ed290() | covered · verified 2026-10-09 |
| ED-291 | Return in the title moves the cursor to the tags field, without adding a line break to the title | L2 | TitleTagsEditorBehaviors/ed291() | covered · verified 2026-10-09 |
| ED-292 | Return in the empty tags field adds an empty row at the top of the outline and puts the cursor in it; Undo removes the row | L2 | TitleTagsEditorBehaviors/ed292() | covered · verified 2026-10-09 |
| ED-293 | Up arrow in the tags field moves the cursor to the end of the title | L2 | TitleTagsEditorBehaviors/ed293() | covered · verified 2026-10-09 |
| ED-294 | Down arrow in the title moves the cursor to the tags field | L2 | TitleTagsEditorBehaviors/ed294() | covered · verified 2026-10-09 |
| ED-295 | Down arrow in the tags field moves the cursor to the end of the first row; in an empty outline it does nothing | L2 | TitleTagsEditorBehaviors/ed295() | covered · verified 2026-10-09 |
| ED-296 | While focused in on a row, Return in the empty tags field moves the cursor to the end of the first row shown instead of adding a row | L2 | TitleTagsEditorBehaviors/ed296() | covered · verified 2026-10-09 |

---

# P2 — Settings, search/replace, tags, links, images, numbering, zoom, history, Open Quickly, backlinks, lock, print, export, share

Drafted 2026-10-10 from reading the code. Nothing here is covered yet: every row is `uncovered`, and the **Layer** column is the layer it would be tested at. A **(?)** marks a sentence I couldn't confirm from the code alone; covering it confirms or rewrites it, as in P1. Behaviors P1 already covers (Focus In/Out ED-238, Hide Completed/Hide Notes ED-135–137 and ED-156, the tags field ED-29x, the create-rows setting ED-033) are not repeated here.

Notes on testing:
- Several settings live in `NSUbiquitousKeyValueStore` (outline defaults, owner, shortcuts menu), not `UserDefaults`. The harness has to prove it can set and reset them per test; that's the first thing Task 23 settles.
- Lock uses `LAContext` (device authentication) and the keychain; tests need a seam for authentication. Print and PDF export go through UIKit printing; test the content that is handed to them, not the print dialog.
- Share (the system share sheet) and Manage Sharing are CloudKit (P3, SY-050–SY-052). Only what Zavala builds before the sheet is P2.

## ST: Settings

Defaults and what each setting changes. "Default" means a fresh install.

| ID | Behavior | Layer | Status |
|---|---|---|---|
| ST-001 | Create Rows defaults to "indented with children": Return at the end of a row with showing children makes a first child (the other choice is ED-033) | L2 | uncovered |
| ST-002 | Editor width defaults to Normal (a readable column, 700 pt scaled to the text size); Wide is 900 pt; Full Width removes the limit, and the editor uses the new width without reopening the outline | L2 | uncovered |
| ST-003 | Row Indent and Row Spacing default to Medium; changing either re-lays out the open outline: Small/Medium/Large change the indent per level, and the spacing above each row (1/2/4 pt for the row highlight) | L2 | uncovered |
| ST-004 | Scroll mode "Typewriter" keeps the typing line vertically centered as the cursor moves; "Normal" only scrolls enough to keep it visible | L2 **(?)** | uncovered |
| ST-005 | "Disable animations" makes scrolling to a row, row-note and title transitions, and centering happen instantly | L2 **(?)** | uncovered |
| ST-006 | Color palette defaults to Automatic (follows the system); Light and Dark force the appearance for every window | L2 | uncovered |
| ST-007 | The Shortcuts menu is hidden by default; turning "show shortcuts menu" on adds it to the menu bar and off removes it | L2 | uncovered |
| ST-008 | "Use main window as default" (Mac only) is off by default; when on, launching with no windows opens the main window instead of a lone outline window **(?)** | L3 | uncovered |
| ST-009 | Outline defaults for a new outline: numbering style None, automatic links on, link-title replacement off, spell checking and auto-correct on; a new outline takes these values, and changing a default does not change existing outlines | L1 | uncovered |
| ST-010 | The Auto-correct switch is disabled while spell checking is off | L3 **(?)** | uncovered |
| ST-011 | Owner name, email, and URL default to empty; a new outline copies them, and the OPML export includes whichever are set (EX-006) | L1 | uncovered |
| ST-012 | The default fonts are Zavala's built-in set (title, tags, numbering, topic, and note per level, plus backlinks); Restore Defaults asks first and is disabled when nothing differs from the defaults | L1 / L3 | uncovered |
| ST-013 | Fonts can have a level added for numbering, topics, or notes; only the deepest added level can be deleted, and level 1 of each can't be | L1 | uncovered |
| ST-014 | A changed font setting changes the open outline's text without reopening it; rows deeper than the last configured level use the last level's font **(?)** | L2 | uncovered |
| ST-016 | "Confirm delete completed rows" is on by default: Delete Completed Rows asks, with "Delete once" and "Always delete"; "Always" turns the confirmation off for later | L2 | uncovered |

## SR: Search and replace

| ID | Behavior | Layer | Status |
|---|---|---|---|
| SR-001 | Searching shows only rows whose text or note contains the query (with their ancestors), and counts every match; the first match is current | L1 | uncovered |
| SR-002 | Search is case-sensitive unless "ignore case" is on, and with "whole words" only matches a standalone word | L1 | uncovered |
| SR-003 | Next/Previous moves the current match through the results and wraps from the last to the first and the first to the last | L1 | uncovered |
| SR-004 | Rows marked complete are skipped while Hide Completed is on; notes are skipped while Hide Notes is on | L1 | uncovered |
| SR-005 | An empty query shows the whole outline with no matches; changing the query replaces the previous results | L1 | uncovered |
| SR-006 | Ending the search restores the whole outline, including collapsed rows, and clears the highlights | L1 / L2 | uncovered |
| SR-007 | Replace changes the current match in a topic or a note, and that match can't be replaced a second time | L1 | uncovered |
| SR-008 | Replace All changes every match, including in notes, in one step | L1 | uncovered |
| SR-009 | Undo of Replace / Replace All restores the text exactly **(?)** — `replaceSearchResults` sets text directly, so there may be no undo step | L1 | uncovered |
| SR-010 | Matches are found regardless of smart quotes and accents **(?)** (`makeSearchable`) | L1 | uncovered |
| SR-011 | Searching a locked outline is unavailable until it is unlocked **(?)** | L2 | uncovered |

## TG: Tags (account level; the tags field in an outline is ED-29x)

| ID | Behavior | Layer | Status |
|---|---|---|---|
| TG-001 | Tag names are trimmed around every "/" part and empty parts are dropped ("  a / b/ " becomes "a/b") | L1 | uncovered |
| TG-002 | Creating a tag that already exists returns the existing one; tags are listed alphabetically ignoring case | L1 | uncovered |
| TG-003 | A tag with a "/" is nested under its parent; creating "a/b/c" also creates "a" and "a/b" | L1 | uncovered |
| TG-004 | A tag's document list includes documents with its sub-tags; selecting several tags shows only documents that have all of them | L1 | uncovered |
| TG-005 | Renaming a tag renames its sub-tags to match; renaming to a name that exists fails with an error and changes nothing | L1 | uncovered |
| TG-006 | Renaming a nested tag to a different parent creates the new parent levels and removes the old ones if nothing else uses them | L1 | uncovered |
| TG-007 | Deleting a tag from a document leaves it in the sidebar while any other document uses it, and removes it (and unused parent levels) when none does | L1 | uncovered |
| TG-008 | Delete Tag in the sidebar removes the tag and its sub-tags from every document, after asking | L1 / L3 | uncovered |
| TG-009 | A document gets a tag only once; adding it again changes nothing | L1 | uncovered |
| TG-010 | New outlines created while one or more tags are selected start with those tags; the same goes for imports | L1 | uncovered |
| TG-011 | The sidebar shows the tags in a tree with the document count of each, updating as documents are tagged | L2 / L3 | uncovered |

## LK: Links

| ID | Behavior | Layer | Status |
|---|---|---|---|
| LK-001 | Copy Row Link puts the current row's Zavala link (`zavala://…`) on the pasteboard; it is the first selected row when several are selected | L2 | uncovered |
| LK-002 | Copy Document Link puts the document's link on the pasteboard | L2 | uncovered |
| LK-003 | Opening a Zavala link to a document opens that document; for a row link, it also shows the row **(?)** | L3 | uncovered |
| LK-004 | Edit Link on selected text (or the link under the cursor) opens a dialog with the link and text; saving sets the link on the text; removing the link leaves the text | L2 | uncovered |
| LK-005 | With "create links automatically" on, URLs and similar data typed or pasted in a row become links; with it off they stay plain text. Each outline has its own setting (Get Info) | L1 | uncovered |
| LK-006 | With "change link titles" on, a link whose text is its URL is replaced by the page's title after a fetch; links with other text are left alone; with it off, nothing is fetched | L1 | uncovered |
| LK-007 | Following a link to a Zavala document adds it to this outline's document links; removing the link (text deleted or link cleared) removes it, whether in a topic or a note | L1 | uncovered |
| LK-008 | Get Info shows the per-outline settings (title, owner, link switches, spelling, numbering); changing them applies to this outline only | L1 / L3 | uncovered |
| LK-009 | A link inside a row survives indent, move, and duplicate; undo of the text edit restores the link **(?)** | L2 | uncovered |

## BL: Backlinks

| ID | Behavior | Layer | Status |
|---|---|---|---|
| BL-001 | When outline A links to outline B, B lists A as a backlink; removing the last link to B removes it | L1 | uncovered |
| BL-002 | An outline's backlinks section appears under its tags when it has any and disappears when it has none | L2 | uncovered |
| BL-003 | Clicking a backlink opens the linking document | L2 / L3 | uncovered |
| BL-004 | Deleting an outline removes its backlinks from the outlines it linked to | L1 | uncovered |
| BL-005 | Duplicating an outline links the copy to the same documents (and registers backlinks on them) | L1 | uncovered |

## IM: Images in rows

| ID | Behavior | Layer | Status |
|---|---|---|---|
| IM-001 | Insert Image adds one image to the current row (topic or note) at the cursor; it appears in the text and stays there after reopening | L2 | uncovered |
| IM-002 | An image keeps its position in the text when text before it is edited | L2 | uncovered |
| IM-003 | Deleting an image's attachment character removes the image | L2 | uncovered |
| IM-004 | Undo/redo of inserting or deleting an image restores it at the same place | L2 | uncovered |
| IM-005 | Duplicating, copying, or pasting a row carries its images to the new row | L1 | uncovered |
| IM-006 | Tapping an image opens it full-screen with a share button; closing returns to the same place | L3 | uncovered |
| IM-007 | An imported OPML/Markdown with images attaches them to their rows | L1 | uncovered |
| IM-008 | A row's images in the topic and in the note are kept apart | L1 | uncovered |

## NM: Numbering

| ID | Behavior | Layer | Status |
|---|---|---|---|
| NM-001 | None shows no numbers. Simple numbers each row 1., 2., 3. among its siblings. Decimal prefixes the parent's number (1.2.1.). Legal uses a different form per level: I., A., 1., a., (1), (a), (i), and "(??)" beyond level 7 | L1 | uncovered |
| NM-002 | Numbers follow the visible order: moving, inserting, deleting, or indenting renumbers at once | L2 | uncovered |
| NM-003 | The numbering style is per outline, defaults from Settings, and changes immediately in the open outline | L2 | uncovered |
| NM-004 | The style is carried in exports: Markdown list uses the row's sibling number when numbering is on (EX-003) | L1 | uncovered |
| NM-005 | The numbering font follows the Settings numbering font for the row's level | L2 **(?)** | uncovered |

## ZM: Text zoom

| ID | Behavior | Layer | Status |
|---|---|---|---|
| ZM-001 | Zoom In and Zoom Out raise or lower every outline font by one point each time; Actual Size returns to 0 | L2 | uncovered |
| ZM-002 | A zoomed font size never goes below 1 point | L1 | uncovered |
| ZM-003 | Zoom applies to the title, tags, numbering, topic, note, and backlinks fonts, in every open window | L2 | uncovered |
| ZM-004 | The zoom level is remembered between launches | L2 **(?)** | uncovered |

## HS: History and navigation

| ID | Behavior | Layer | Status |
|---|---|---|---|
| HS-001 | Back and Forward are unavailable when their stacks are empty | L2 | uncovered |
| HS-002 | Opening another document from the list puts the previous one on the Back stack; Back returns to it and Forward goes to the one you left | L2 | uncovered |
| HS-003 | Opening a new document after going Back clears the Forward stack | L2 | uncovered |
| HS-004 | The Back stack keeps the 10 most recent entries | L2 | uncovered |
| HS-005 | Clicking the same document twice in a row doesn't add it twice to the Back stack | L2 | uncovered |
| HS-006 | Back/Forward is saved with the window and restored on relaunch | L3 **(?)** | uncovered |
| HS-007 | The recently opened list (Open Recent, shortcut items) shows the last documents opened, most recent first, 4 as app shortcuts; documents that were deleted drop out | L2 | uncovered |

## OQ: Open Quickly

| ID | Behavior | Layer | Status |
|---|---|---|---|
| OQ-001 | Open Quickly lists all documents that aren't locked in an active account and filters them as you type (autocomplete) | L2 / L3 | uncovered |
| OQ-002 | Choosing a result (click, Return, or Done) opens that document and closes the dialog; Cancel closes it with no change | L2 / L3 | uncovered |
| OQ-003 | Done is disabled until the typed text matches at least one result | L2 | uncovered |
| OQ-004 | On Mac, the dialog shows a collection list beside the documents, and remembers the last collection | L3 **(?)** | uncovered |

## LC: Lock

| ID | Behavior | Layer | Status |
|---|---|---|---|
| LC-001 | Add Lock asks the device to authenticate, then locks the outline: it's shown as locked and its content is hidden until unlocked | L2 | uncovered |
| LC-002 | Locking removes the outline from the Spotlight index; Remove Lock puts it back **(?)** (encrypted storage itself is out of scope) | L1 | uncovered |
| LC-003 | Opening a locked outline asks for authentication; after unlocking, the outline stays open until locked again | L2 | uncovered |
| LC-004 | Lock Now re-locks every unlocked outline; it's only available when at least one is unlocked | L2 | uncovered |
| LC-005 | Outlines lock themselves after the app has been in the background for 8 minutes on Mac (3 on iPad), and whenever the device locks | L2 | uncovered |
| LC-006 | Add Lock is unavailable while the outline is shared; Share and Manage Sharing are unavailable while locked | L2 | uncovered |
| LC-007 | Shortcuts and Siri actions refuse locked outlines and leave them out of results | L1 | uncovered |
| LC-008 | Remove Lock is available only while the outline is unlocked | L2 | uncovered |
| LC-009 | Authentication cancelled or failed leaves the outline as it was and shows an error | L2 | uncovered |

## PR: Print

| ID | Behavior | Layer | Status |
|---|---|---|---|
| PR-001 | Print Doc prints the outline as a document: the title, then rows as headings, paragraphs, and lists (the same structure as the Markdown Doc export) | L1 | uncovered |
| PR-002 | Print List prints the outline as an indented list that follows the outline's numbering style | L1 | uncovered |
| PR-003 | Print Doc, Print List, and Print Screen are unavailable when no outline is open | L2 | uncovered |
| PR-004 | Printing several selected documents prints each one in turn | L2 / L3 **(?)** | uncovered |

## EX: Export

Output only; the saved-file format is out of scope (SPEC).

| ID | Behavior | Layer | Status |
|---|---|---|---|
| EX-001 | Markdown List starts with `# Title`, then each row as a list item (`*`, or the sibling number when numbering is on) nested with tabs, notes indented under the item | L1 | uncovered |
| EX-002 | Completed rows are exported as struck through (`~~text~~`) in Markdown | L1 | uncovered |
| EX-003 | Markdown Doc turns rows with a note into headings (deeper rows into deeper headings) and rows without a note into list items | L1 | uncovered |
| EX-004 | Rows with links, bold, italic, and code are exported with their Markdown syntax; Zavala links use relative file links in Markdown and HTML, and the alt link form when requested **(?)** | L1 | uncovered |
| EX-005 | HTML List and HTML Doc are the Markdown exports rendered as one HTML page, with the title in `<title>` | L1 | uncovered |
| EX-006 | OPML export has the title, dates, owner fields, tags, each row as `<outline text=… _note=… _status="checked">` nested by level, plus Zavala's own settings (numbering, link and spelling switches) | L1 | uncovered |
| EX-007 | Special characters are escaped in OPML and HTML (&, <, >, quotes) | L1 | uncovered |
| EX-008 | PDF export (Doc and List) saves the same content as Print Doc / Print List **(?)** | L1 / L3 | uncovered |
| EX-009 | Exporting several documents saves one file per document, named after the document | L3 | uncovered |
| EX-010 | Exporting a locked outline is unavailable | L2 | uncovered |
| EX-011 | Export includes images (as files beside the Markdown, or inline for HTML) **(?)** (`useSidecar`) | L1 | uncovered |
| EX-012 | OPML import is the fixture loader; a round trip of export then import gives back the same rows, completion, and notes | L1 | uncovered |

## SH: Share (not CloudKit)

| ID | Behavior | Layer | Status |
|---|---|---|---|
| SH-001 | Share offers the document as OPML, Markdown, or PDF **(?)** through the system share sheet, named after the document | L3 **(?)** | uncovered |
| SH-002 | Share is unavailable when no outline is open | L2 | uncovered |
| SH-003 | Sharing several documents offers all of them at once | L3 **(?)** | uncovered |
| SH-004 | Sharing an image from the image viewer offers that image | L3 **(?)** | uncovered |

## Gaps and proposals (for your review)

- **Not in your P2 list, but found:** Get Info (per-outline settings, LK-008), Delete Completed Rows confirmation (ST-016), font settings (ST-012–014). I put them under the nearest area; tell me if you'd rather drop them.
- **Many of these are not worth covering for the fork** — for example ST-004/005 (scroll mode, animations), SH-*, PR-004 are UI plumbing. Proposed bar: cover L1 and L2 rows; leave rows marked L3, `(?)`, or in a UI dialog as inventory unless you promote them.
- **Likely bugs to look for while covering:** SR-009 (Replace may not be undoable), LK-009, NM-005, HS-006.

---

# P3 — Sync / CloudKit (inventory only)

Drafted 2026-10-10 from reading `VinOutlineKit/CloudKit/*`, the `*+CloudKit.swift` files, and the sync call sites in `Zavala/`. **No tests, no mutation patches**: SPEC says P3 is inventory-only unless promoted, and it's low priority because this area will be heavily reworked. Every row is `uncovered`. Nothing here was run against iCloud; sentences come from the code. IDs are `SY-nnn`, stable like the others. Sentences about merge and zone handling are the ones most likely to change under the fork; I've marked them **(rework)**.

Persistence format, record field names, and CloudKit record shape are out of scope (SPEC). Rows below say what the user sees, and mention records only where the behavior is about them.

## SY: Account and setup

| ID | Behavior | Status |
|---|---|---|
| SY-001 | The iCloud account is optional: the Accounts settings have an "enable iCloud" switch, and turning it on creates the iCloud account (a section in the sidebar) and syncs for the first time | uncovered |
| SY-002 | Turning the iCloud switch off asks for confirmation ("remove iCloud account"); cancelling leaves it on, confirming removes the account and its documents from this device | uncovered |
| SY-003 | The iCloud switch is disabled in developer builds | uncovered |
| SY-004 | First-time setup creates the iCloud zone if it doesn't exist and subscribes to private and shared changes, so other devices' edits arrive by notification | uncovered |
| SY-005 | A document created, duplicated, or imported in the iCloud account is queued for upload as soon as it exists (create, import OPML/Markdown, duplicate) | uncovered |
| SY-006 | Removing the iCloud account clears the stored shared-database change token, so a later re-enable fetches everything again | uncovered |
| SY-007 | If the iCloud zone was written by an app with a different zone version, syncing stops with an "incompatible version" error instead of changing the data **(rework)** | uncovered |

## SY: When a sync happens

| ID | Behavior | Status |
|---|---|---|
| SY-010 | Sync runs when the app becomes active, when it enters the background (it finishes before the app suspends), and on the Sync menu command | uncovered |
| SY-011 | Edits are queued, then sent about 5 seconds after the last queued change (debounced), without the user asking | uncovered |
| SY-012 | A remote-change notification sends pending changes first, then fetches only what the notification names (the private zone, a shared zone, or all changes) | uncovered |
| SY-013 | With no network, a sync call returns without doing anything and queued edits wait; when the network comes back the next debounce tick sends them | uncovered |
| SY-014 | A network failure never shows an error: the sync is retried on the next tick. Any other sync error shows an "iCloud Syncing Error" alert | uncovered |
| SY-015 | While a sync runs, a spinner next to the iCloud account in the sidebar animates; it stops when the sync completes (including when it failed) | uncovered |
| SY-016 | A sync that is already sending or fetching doesn't overlap another: the second waits its turn | uncovered |

## SY: Sending local edits

| ID | Behavior | Status |
|---|---|---|
| SY-020 | Every local change to an outline (title, tags, numbering, link settings, lock, rows, images) queues an update for just the pieces that changed | uncovered |
| SY-021 | A multi-row edit queues all its updates together (a batch), not one send per row | uncovered |
| SY-022 | Queued updates survive quitting the app: they're stored on disk and sent on the next sync | uncovered |
| SY-023 | Several queued updates for the same row are sent as one save of the row's current state | uncovered |
| SY-024 | A queued update for a row, image, or document that no longer exists is sent as a delete; deleting a document deletes its rows and images with it | uncovered |
| SY-025 | A save is accepted only if the server's copy hasn't changed since this device last saw it; otherwise the device merges (see SY-040s) and sends again | uncovered |
| SY-026 | If the send fails, all requests that were taken for it are put back in the queue; if it partly succeeds, only the unsent ones are | uncovered |
| SY-027 | A locked outline's row text and notes are encrypted before they're sent | uncovered |

## SY: Receiving remote edits

| ID | Behavior | Status |
|---|---|---|
| SY-030 | A remote edit to a row's text, note, completion, position, or parent shows up in the outline, and in the open editor if that outline is on screen | uncovered |
| SY-031 | A row added elsewhere appears at the position its order value says, under the parent it names | uncovered |
| SY-032 | A row deleted elsewhere disappears here, with its children | uncovered |
| SY-033 | A remote image added, moved, or deleted shows up on the right row | uncovered |
| SY-034 | A remote change to the title, tags, numbering style, link settings, lock state, or backlinks updates the document; removed tags are deleted from the account if nothing else uses them | uncovered |
| SY-035 | A document created or deleted on another device appears in or disappears from the document list | uncovered |
| SY-036 | A remote record that matches the one this device already holds (same change tag) is ignored | uncovered |
| SY-037 | A remote change to a record that has a pending local update is ignored until the local update has been sent (it then merges, SY-040s) | uncovered |
| SY-038 | A document changed by sync posts a "changed by sync" notification so the list and search index refresh | uncovered |
| SY-039 | If the remote zone is deleted by the user in iCloud settings, the device removes its documents for that zone and shows an error; if the zone is simply missing, it removes the documents without an error | uncovered |

## SY: Merging concurrent edits **(rework)**

| ID | Behavior | Status |
|---|---|---|
| SY-040 | When two devices change different fields of the same record, both changes survive | uncovered |
| SY-041 | When two devices change the same field, the local change wins for text fields, and the server value wins when only the server changed it (three-way merge against the last synced value) | uncovered |
| SY-042 | A row's text and its note are merged as attributed strings, not as whole values | uncovered |
| SY-043 | Rows keep a fractional-index order, so rows inserted at different places on two devices both appear in a consistent order | uncovered |
| SY-044 | A document from the older "row order list" format is migrated to fractional ordering the first time it's received, and the result is sent back | uncovered |
| SY-045 | The lock state merges like other fields; if the encryption key isn't on this device yet, the device retries up to 5 times, 2 seconds apart, before giving up (rows stay unreadable) | uncovered |

## SY: Sharing

| ID | Behavior | Status |
|---|---|---|
| SY-050 | Share is unavailable when sync isn't available (no iCloud account, or the iCloud account is off) | uncovered |
| SY-051 | Choosing Share on a document in the iCloud account creates (or reuses) a share named after the document, shows the system sharing sheet, and syncs afterwards | uncovered |
| SY-052 | Stopping sharing from the sheet triggers a sync | uncovered |
| SY-053 | Opening a share link accepts the share, fetches the shared zone, and opens the shared document | uncovered |
| SY-054 | Shared documents sit in the same iCloud list as the user's own documents, in their owner's zone; edits sync both ways through the shared database | uncovered |
| SY-055 | If a document knows it's shared but lost the share record locally, the share record is fetched again the next time the account loads | uncovered |
| SY-056 | The owner sees changes to the share (participants, stop sharing) because share records arriving or being deleted update the document | uncovered |

## Notes for the fork

- Almost all of this goes away or changes if the fork replaces CloudKit (SPEC mentions Automerge). SY-001–003, SY-015, SY-050–052 are user-facing and survive any sync backend; the rest describe CloudKit mechanics.
- Testing this would need a fake `CKDatabase`/`CKContainer` (or a seam around `VCKZone`); there is none, and `CloudKitManager` creates its container directly. A promotion to tests would start with a seam, which is a production-code change.
- Sentences I'm least sure of (marked by what I'd check first): SY-037 (`cloudKitDidModify` skips records that have pending requests, but I haven't confirmed a later fetch brings them back), SY-041 (the `merge(client:ancestor:server:)` rule lives in VinCloudKit, a dependency I didn't read), SY-016 (`syncSemaphore` guards `sendChanges` and `fetchChanges`, not `fetchAllChanges` as a whole).

---

# Command map

Every editing command and its behaviors, as a cross-check. A command without an ID is unaccounted for.

| Command / key | Behaviors |
|---|---|
| Tab / Shift-Tab, Move Right/Left (Ctrl-Cmd-→/←) · MoveRowRightCommand, MoveRowLeftCommand | ED-010–022, ED-237 |
| Return · CreateRowAfterCommand, CreateRowBeforeCommand, SplitRowCommand | ED-030–036, ED-043, ED-050–051 |
| Shift-Return (insertRow) · CreateRowBeforeCommand | ED-037 |
| Shift-Option-Return (split) | ED-053 |
| Ctrl-Return Add Row Below, menu Add Row Above | ED-038 |
| Cmd-} Add Row Inside · CreateRowInsideCommand | ED-039, ED-041 |
| Cmd-{ Add Row Outside · CreateRowOutsideCommand | ED-040 |
| Delete (topic) · JoinRowCommand, DeleteRowCommand | ED-054–057, ED-059, ED-070–071 |
| Shift-Cmd-Delete Delete Rows · DeleteRowCommand | ED-072–074, ED-076 |
| Cmd-D Delete Completed Rows | ED-075 |
| Ctrl-Cmd-↑/↓ · MoveRowUpCommand, MoveRowDownCommand | ED-090–095 |
| Cmd-0 / Cmd-9 · CollapseCommand, ExpandCommand | ED-110–111, ED-116–117 |
| Opt-Cmd-0/9, Ctrl-Cmd-0/9 · CollapseAllCommand, ExpandAllCommand | ED-112–113 |
| Ctrl-Opt-Cmd-0 Collapse Parent Row | ED-114 |
| Disclosure triangle | ED-115 |
| Cmd-Return · CompleteCommand, UncompleteCommand | ED-130–135 |
| Hide Completed (filter), Turn Filter On (Shift-Cmd-H) | ED-135–137, ED-156 |
| Ctrl-- · CreateNoteCommand | ED-150–151 |
| Ctrl-Shift-- · DeleteNoteCommand; Delete in empty note | ED-152–153 |
| Option-Return, Option-Tab | ED-154–155 |
| Hide Notes (filter) | ED-156 |
| Copy, Cut · CutRowCommand; Paste · PasteRowCommand | ED-170–173, ED-175 |
| Ctrl-Cmd-R · DuplicateRowCommand | ED-174–175 |
| Drag/drop · LocalDropRowCommand, RemoteDropRowCommand | ED-190–194 |
| Opt-Cmd-G · GroupRowsCommand | ED-210–211, ED-214 |
| Opt-Cmd-S · SortRowsCommand | ED-212–214 |
| ↑ ↓, Ctrl-P, Ctrl-N | ED-230–235 |
| Esc (toggle mode) | ED-236 |
| Opt-Cmd-→/← Focus In/Out | ED-238–239, ED-043 |
| Typing · TextChangedCommand | ED-022, ED-042, ED-252 |
| Undo/Redo | every edit test, ED-250–252 |
| Cmd-B, Cmd-I, Ctrl-Opt-Cmd-C, Ctrl-Opt-Cmd-H | ED-270–276 |
| Title row, tags field | ED-233, ED-290–296 |
| CreateTagCommand, DeleteTagCommand, ReplaceSearchResultCommand | P2 (tags, search/replace) |

---

# Known Zavala bugs

Places where Zavala behaves wrongly. The test asserts the correct behavior and wraps the wrong part in `withKnownIssue("ZB-nnn …")`, so the suite stays green. If the fork fixes the bug, that test fails with "Known issue was not recorded". Then remove the `withKnownIssue`, mark the bug fixed here, and add a divergence entry.

| ID | Bug | Behaviors | Status |
|---|---|---|---|
| ZB-001 | Undo doesn't reverse automatic completion changes made by indent: undo moves the row back but the new parent keeps its changed completion. (Outdent's undo does reverse it, ED-021.) | ED-019, ED-020 | open |
| ZB-002 | Return in an empty last child outdents it only if the row never had text. Once text was typed and deleted, Return creates another empty row above instead, because the outdent check (`Outline.shouldMoveLeftOnReturn`) requires no topic at all rather than an empty one. | ED-035 | open |
| ZB-003 | Delete at the start of a row that has children doesn't join it (correct), but Zavala still records a join, so the next Undo inserts that row a second time. The editor checks only that the row above is a sibling; the "no children" check is in `Outline.joinRows`, after `JoinRowCommand` has registered its undo. | ED-056 | open |
| ZB-004 | Joining rows (Delete at the start of a row) drops the lower row's note; only its text is kept. Undo brings the note back. `Outline.joinRows` updates the upper row's topic and deletes the lower row without carrying its note over. | ED-059 | open |
| ZB-005 | Undo of deleting a collapsed row puts its hidden descendants at the top of the outline, flattened, and leaves the row without children. `DeleteRowCommand` remembers each deleted row's place by the visible row above it, and hidden rows have none, so undo inserts them at the top. | ED-076 | open |
| ZB-006 | Undo of a delete changes the completion of the restored rows' parents: putting back a completed child marks its parent complete, and putting back an incomplete child marks a completed parent incomplete. Undo doesn't restore the earlier completion (same family as ZB-001). | ED-075 | open |
| ZB-007 | After deleting several rows in row-selection mode, the selection lands at a different place from run to run. `DeleteRowCommand` keeps the rows in a `Set`, so "the first deleted row" is whichever comes out first. Intermittent: the test marks it `isIntermittent`. | ED-074 | open |
| ZB-008 | Collapse All in Outline, or Option-clicking a disclosure triangle, while the cursor is in a row it hides leaves nothing focused: the cursor is gone. Plain Collapse moves the cursor to the end of the collapsed row (`EditorViewController.collapse(rows:)`); `collapseAll(containers:)` has no such step. | ED-117 | open |
| ZB-009 | Undo of Complete marks every row it was given incomplete, including rows that were already complete. `CompleteCommand.undo` calls `uncomplete(rows:)` on all of them instead of only those it changed. | ED-134 | open |
| ZB-010 | Redo of Duplicate Rows puts the copies after the first duplicated row instead of the last. `DuplicateRowCommand.perform` re-inserts with `afterRow: rows.sortedByDisplayOrder().first`, while the first run (`Outline.duplicateRows`) inserts after the last. | ED-174 | open |
| ZB-011 | Undo of Cut puts a row back at the end of its level when the row shown above it was another row's child. `CutRowCommand` remembers the visible row above, not that row's ancestor among the cut row's siblings (`DeleteRowCommand` uses `ancestorSibling` for this). | ED-171 | open |
| ZB-012 | Typing in a row and then pressing Tab or Return doesn't give the typing its own undo step. After Tab, one Undo reverts the indent and the typing together. After Return, Undo removes the new row and keeps the typing, but the typing is never undone: the next Undo reverts the edit before it, so undo runs out of order. Happens with or without a pause before the key. Found with real keystrokes (L3, `SmokeFlows`). The L2 test for ED-252 used to hide it by saving the typing as its own undo step first (`commitTyping()`), which real typing never does; it now types without saving and shows it too. | ED-252 | open |

---

# Observed Zavala quirks

Current behaviors that look unintended. They're recorded so the fork can decide on purpose whether to keep them. These aren't tested unless promoted to a numbered behavior.

- Undo is inconsistent about text typed just before an edit: indent's undo restores the earlier text (ED-022), create-row's doesn't (ED-042). With real keys, typing gets no undo step of its own (ZB-012), so this shows every time.
- Outdent collects the rows below the outdented row (`siblingsToMove` in `Outline.moveRowsLeft`) but never uses them; those rows stay under the old parent (ED-015).
- Forward Delete at the end of a row joins the next visible row onto it, without the sibling check that Delete uses (`EditorViewController.pressesBegan`). Not in the inventory yet: the harness can't send hardware key presses.
- Pasting copied rows while editing a row's text inserts them as Markdown text in that row ("Alpha * Bravo / * B1") instead of as rows: the text view handles Paste before the editor does. Checked with a throwaway test, not covered by one.
- Pasting text into a row adds a space on each side of it (the system's smart paste, ED-173).
- OPML import ignores `<expansionState>`: it's applied before the rows exist (`Account.importOPML`), so every imported row opens expanded.


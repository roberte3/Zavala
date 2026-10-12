//
//  ClipboardBehaviors.swift
//  VinOutlineKitTests
//
//  ED-170 … ED-175: Cut, copy, paste, duplicate (model level). Editor-level ones, which go through
//  the clipboard, are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Cut, copy, paste, duplicate")
final class ClipboardBehaviors: VOKTestCase {

	@Test("ED-172 Pasting rows inserts them after the current row at the same level, or as first children when its children are showing")
	func ed172() async throws {
		let original = """
			- A
			  - A1
			- B
			- (+) C
			  - C1
			- D
			"""
		let copied = """
			- X
			  > x note
			  - X1
			- [x] Y
			"""

		// After a row without children: same level, just below it.
		try await paste(copied, after: "B", into: original, expecting: """
			- A
			  - A1
			- B
			- X
			  > x note
			  - X1
			- [x] Y
			- (+) C
			  - C1
			- D
			""")

		// After a row whose children are showing: its first children.
		try await paste(copied, after: "A", into: original, expecting: """
			- A
			  - X
			    > x note
			    - X1
			  - [x] Y
			  - A1
			- B
			- (+) C
			  - C1
			- D
			""")

		// After a collapsed row: same level, after its hidden children.
		try await paste(copied, after: "C", into: original, expecting: """
			- A
			  - A1
			- B
			- (+) C
			  - C1
			- X
			  > x note
			  - X1
			- [x] Y
			- D
			""")
	}

	@Test("ED-174 Duplicate Rows (Ctrl-Cmd-R) inserts a copy of the selected rows, with children, just after the last of them")
	func ed174() async throws {
		let original = """
			- A
			- B
			  > b note
			  - B1
			- [x] C
			- D
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		DuplicateRowCommand(actionName: "Duplicate Rows", undoManager: undoManager, delegate: self, outline: outline,
							rows: [try outline.row(titled: "B"), try outline.row(titled: "C")]).execute()

		let after = """
			- A
			- B
			  > b note
			  - B1
			- [x] C
			- B
			  > b note
			  - B1
			- [x] C
			- D
			"""
		expectOutline(outline, after)
		undoManager.undo()
		expectOutline(outline, original)
		undoManager.redo()
		withKnownIssue("ZB-010 Redo of Duplicate Rows puts the copies after the first duplicated row instead of the last") {
			expectOutline(outline, after)
		}
	}

	@Test("ED-175 Pasted and duplicated rows are new rows; changing them doesn't change the originals")
	func ed175() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			""")
		defer { deleteAccountManager(accountManager) }
		let a = try outline.row(titled: "A")

		DuplicateRowCommand(actionName: "Duplicate Rows", undoManager: undoManager, delegate: self, outline: outline, rows: [a]).execute()
		PasteRowCommand(actionName: "Paste", undoManager: undoManager, delegate: self, outline: outline,
						rowGroups: [RowGroup(a)], afterRow: try outline.row(titled: "B"), childRowIndent: true).execute()
		expectOutline(outline, """
			- A
			  - A1
			- A
			  - A1
			- B
			- A
			  - A1
			""")

		// Edit the copies (rows 2 and 4) and their children.
		let duplicate = outline.rows[1]
		let pasted = outline.rows[3]
		#expect(Set([a.id, duplicate.id, pasted.id]).count == 3)
		#expect(Set([a.rows[0].id, duplicate.rows[0].id, pasted.rows[0].id]).count == 3)
		duplicate.topic = NSAttributedString(string: "Duplicate")
		duplicate.rows[0].topic = NSAttributedString(string: "Duplicate child")
		pasted.topic = NSAttributedString(string: "Pasted")
		pasted.rows[0].topic = NSAttributedString(string: "Pasted child")
		CompleteCommand(actionName: "Complete", undoManager: undoManager, delegate: self, outline: outline,
						rows: [pasted.rows[0]], rowStrings: nil).execute()

		expectOutline(outline, """
			- A
			  - A1
			- Duplicate
			  - Duplicate child
			- B
			- [x] Pasted
			  - [x] Pasted child
			""")
	}

	// MARK: Helpers

	/// Pastes the rows of `copied` (as copied from another outline) after `title` in a fresh `original`,
	/// and checks the result, undo, and redo.
	private func paste(_ copied: String, after title: String, into original: String, expecting after: String,
					   sourceLocation: SourceLocation = #_sourceLocation) async throws {
		let (source, sourceManager) = try await makeOutline(copied, sourceLocation: sourceLocation)
		defer { deleteAccountManager(sourceManager) }
		let (outline, accountManager) = try await makeOutline(original, sourceLocation: sourceLocation)
		defer { deleteAccountManager(accountManager) }
		undoManager.removeAllActions()

		PasteRowCommand(actionName: "Paste", undoManager: undoManager, delegate: self, outline: outline,
						rowGroups: source.rows.map(RowGroup.init), afterRow: try outline.row(titled: title, sourceLocation: sourceLocation),
						childRowIndent: true).execute()

		expectEdit(outline, before: original, after: after, sourceLocation: sourceLocation)
		expectOutline(source, copied, sourceLocation: sourceLocation)
	}
}

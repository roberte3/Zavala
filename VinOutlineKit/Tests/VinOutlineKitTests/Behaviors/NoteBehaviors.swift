//
//  NoteBehaviors.swift
//  VinOutlineKitTests
//
//  ED-150 … ED-156: Notes and in-row text (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Notes")
final class NoteBehaviors: VOKTestCase {

	@Test("ED-152 Delete Note (Ctrl-Shift--) removes the note from the selected rows; undo brings the text back")
	func ed152() async throws {
		let original = """
			- A
			  > a note
			  > second line
			- B
			  > b note
			- C
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		let a = try outline.row(titled: "A")
		let b = try outline.row(titled: "B")
		let c = try outline.row(titled: "C")

		// What the Delete Note menu item checks.
		#expect(outline.isDeleteNotesUnavailable(rows: [c]))
		#expect(!outline.isDeleteNotesUnavailable(rows: [a, c]))

		DeleteNoteCommand(actionName: "Delete Note", undoManager: undoManager, delegate: self, outline: outline,
						  rows: [a, b], rowStrings: nil).execute()

		expectEdit(outline, before: original, after: """
			- A
			- B
			- C
			""")
	}
}

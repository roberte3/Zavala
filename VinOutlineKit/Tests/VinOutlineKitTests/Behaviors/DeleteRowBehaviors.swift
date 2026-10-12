//
//  DeleteRowBehaviors.swift
//  VinOutlineKitTests
//
//  ED-070 … ED-076: Deleting rows (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Deleting rows")
final class DeleteRowBehaviors: VOKTestCase {

	@Test("ED-073 Deleting the last incomplete child of a row whose other children are complete marks that row complete")
	func ed073() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - [x] A1
			  - A2
			""")
		defer { deleteAccountManager(accountManager) }

		delete(["A2"], in: outline)

		expectEdit(outline, before: """
			- A
			  - [x] A1
			  - A2
			""", after: """
			- [x] A
			  - [x] A1
			""")
	}

	@Test("ED-076 Undo of a delete restores the rows, with children, in their original positions")
	func ed076() async throws {
		let original = """
			- A
			  - A1
			  - A2
			    - A2a
			- (+) B
			  - B1
			    - B1a
			  - B2
			- C
			  > c note
			- [x] D
			"""

		// A first child, a row with showing children, a top-level row, and a completed row, all at once.
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		delete(["A1", "A2", "C", "D"], in: outline)
		expectEdit(outline, before: original, after: """
			- A
			- (+) B
			  - B1
			    - B1a
			  - B2
			""")

		// A collapsed row; its children are hidden.
		let (collapsed, collapsedManager) = try await makeOutline(original)
		defer { deleteAccountManager(collapsedManager) }
		undoManager.removeAllActions()
		delete(["B"], in: collapsed)
		expectEdit(collapsed, before: original, after: """
			- A
			  - A1
			  - A2
			    - A2a
			- C
			  > c note
			- [x] D
			""", knownUndoBug: "ZB-005 Undo of deleting a collapsed row puts its hidden descendants at the top of the outline, flattened")
	}

	// MARK: Helpers

	/// What Delete Rows does with these rows selected.
	private func delete(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		DeleteRowCommand(actionName: "Delete Rows", undoManager: undoManager, delegate: self, outline: outline,
						 rows: rows, currentRow: nil, rowStrings: nil, isInOutlineMode: true).execute()
	}
}

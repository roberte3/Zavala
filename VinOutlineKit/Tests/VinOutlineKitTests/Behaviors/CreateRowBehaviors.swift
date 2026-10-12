//
//  CreateRowBehaviors.swift
//  VinOutlineKitTests
//
//  ED-030 … ED-043: Creating rows (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Creating rows")
final class CreateRowBehaviors: VOKTestCase {

	@Test("ED-031 Return at the end of a row whose children are showing creates the new row as its first child")
	func ed031() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		createRow(after: "A", in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			- B
			""", after: """
			- A
			  -
			  - A1
			- B
			""")
	}

	@Test("ED-032 Return at the end of a collapsed row with children creates the new row as its next sibling, after the hidden children")
	func ed032() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- (+) A
			  - A1
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		createRow(after: "A", in: outline)

		expectEdit(outline, before: """
			- (+) A
			  - A1
			- B
			""", after: """
			- (+) A
			  - A1
			-
			- B
			""")
	}

	@Test("ED-040 Add Row Outside creates an empty row just after the current row's parent, and is unavailable for top-level rows")
	func ed040() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - A2
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		#expect(outline.isCreateRowOutsideUnavailable(rows: [try outline.row(titled: "B")]))
		#expect(!outline.isCreateRowOutsideUnavailable(rows: [try outline.row(titled: "A1")]))

		CreateRowOutsideCommand(actionName: "Add Row Outside", undoManager: undoManager, delegate: self, outline: outline,
								afterRow: try outline.row(titled: "A1"), rowStrings: nil).execute()

		expectEdit(outline, before: """
			- A
			  - A1
			  - A2
			- B
			""", after: """
			- A
			  - A1
			  - A2
			-
			- B
			""")
	}

	@Test("ED-041 Creating a row inside a completed row marks that row incomplete")
	func ed041() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- [x] A
			  - [x] A1
			""")
		defer { deleteAccountManager(accountManager) }

		createRow(after: "A", in: outline)

		expectEdit(outline, before: """
			- [x] A
			  - [x] A1
			""", after: """
			- A
			  -
			  - [x] A1
			""")
	}

	@Test("ED-042 Text typed into the current row before creating a new row is kept; undo removes only the new row and leaves the text")
	func ed042() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		createRow(after: "A", in: outline, typed: "A typed")
		let after = """
			- A typed
			-
			- B
			"""
		expectOutline(outline, after)

		// Unlike indent (ED-022), undo doesn't restore the earlier text; in the app, typing has its own undo step.
		undoManager.undo()
		expectOutline(outline, """
			- A typed
			- B
			""")

		undoManager.redo()
		expectOutline(outline, after)
	}

	@Test("ED-043 While focused on a row, Return at the end of the focused row creates its first child")
	func ed043() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		outline.focusIn(try outline.row(titled: "A"))
		createRow(after: "A", in: outline)

		expectEdit(outline, before: """
			- A
			- B
			""", after: """
			- A
			  -
			- B
			""")
	}

	// MARK: Helpers

	/// What Return at the end of a row does, with Zavala's default "create rows indented with children" setting.
	private func createRow(after title: String, in outline: Outline, typed: String? = nil, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let row = try? outline.row(titled: title, sourceLocation: sourceLocation) else { return }
		CreateRowAfterCommand(actionName: "Add Row", undoManager: undoManager, delegate: self, outline: outline,
							  afterRow: row, rowStrings: typed.map { .topic(NSAttributedString(string: $0)) },
							  childRowIndent: true).execute()
	}
}

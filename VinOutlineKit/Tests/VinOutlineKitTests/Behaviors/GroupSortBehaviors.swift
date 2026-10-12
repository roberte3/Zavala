//
//  GroupSortBehaviors.swift
//  VinOutlineKitTests
//
//  ED-210 … ED-214: Group and sort rows (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Group and sort")
final class GroupSortBehaviors: VOKTestCase {

	@Test("ED-211 Group Rows is unavailable when the selected rows aren't adjacent siblings")
	func ed211() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			- C
			- D
			""")
		defer { deleteAccountManager(accountManager) }
		let row = { (title: String) in try outline.row(titled: title) }

		#expect(outline.isGroupRowsUnavailable(rows: [try row("B"), try row("D")]))
		#expect(outline.isGroupRowsUnavailable(rows: [try row("A1"), try row("B")]))
		#expect(!outline.isGroupRowsUnavailable(rows: [try row("B"), try row("C")]))
		#expect(!outline.isGroupRowsUnavailable(rows: [try row("C")]))
	}

	@Test("ED-212 Sort Rows (Opt-Cmd-S) sorts the selected adjacent siblings alphabetically, ignoring case; children move with their rows")
	func ed212() async throws {
		let original = """
			- zulu
			- cherry
			  - c1
			- apple
			- Banana
			  - b1
			- Able
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		// Everything but the first and last rows. Sorting by case would put "Banana" before "apple".
		sort(["cherry", "apple", "Banana"], in: outline)

		expectEdit(outline, before: original, after: """
			- zulu
			- apple
			- Banana
			  - b1
			- cherry
			  - c1
			- Able
			""")
	}

	@Test("ED-213 Sort Rows is unavailable for a single row or rows that aren't adjacent siblings")
	func ed213() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			- C
			- D
			""")
		defer { deleteAccountManager(accountManager) }
		let row = { (title: String) in try outline.row(titled: title) }

		#expect(outline.isSortRowsUnavailable(rows: [try row("C")]))
		#expect(outline.isSortRowsUnavailable(rows: [try row("B"), try row("D")]))
		#expect(outline.isSortRowsUnavailable(rows: [try row("A1"), try row("B")]))
		#expect(!outline.isSortRowsUnavailable(rows: [try row("B"), try row("C")]))
	}

	@Test("ED-214 Undo of group or sort restores the original structure and order")
	func ed214() async throws {
		// Group: rows with children and completion, in the middle of their parent.
		let original = """
			- A
			  - A1
			  - [x] A2
			    - [x] A2a
			  - A3
			    > a3 note
			  - A4
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		GroupRowsCommand(actionName: "Group Rows", undoManager: undoManager, delegate: self, outline: outline,
						 rows: [try outline.row(titled: "A2"), try outline.row(titled: "A3")], rowStrings: nil).execute()

		expectEdit(outline, before: original, after: """
			- A
			  - A1
			  -
			    - [x] A2
			      - [x] A2a
			    - A3
			      > a3 note
			  - A4
			""")

		// Sort, then undo: the original order comes back exactly, not just sorted the other way.
		let unsorted = """
			- C
			- A
			- D
			- B
			"""
		let (sorted, sortedManager) = try await makeOutline(unsorted)
		defer { deleteAccountManager(sortedManager) }
		undoManager.removeAllActions()
		sort(["C", "A", "D", "B"], in: sorted)
		expectEdit(sorted, before: unsorted, after: """
			- A
			- B
			- C
			- D
			""")
	}

	// MARK: Helpers

	private func sort(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		SortRowsCommand(actionName: "Sort Rows", undoManager: undoManager, delegate: self, outline: outline, rows: rows).execute()
	}
}

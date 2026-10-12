//
//  CompleteBehaviors.swift
//  VinOutlineKitTests
//
//  ED-130 … ED-137: Completing rows (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Completing rows")
final class CompleteBehaviors: VOKTestCase {

	@Test("ED-131 Completing a row doesn't change its children's completion")
	func ed131() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - [x] A2
			""")
		defer { deleteAccountManager(accountManager) }

		complete(["A"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			  - [x] A2
			""", after: """
			- [x] A
			  - A1
			  - [x] A2
			""")
	}

	@Test("ED-132 Completing the last incomplete child of a row marks that row complete too")
	func ed132() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - [x] A1
			  - A2
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		complete(["A2"], in: outline)

		expectEdit(outline, before: """
			- A
			  - [x] A1
			  - A2
			- B
			""", after: """
			- [x] A
			  - [x] A1
			  - [x] A2
			- B
			""")
	}

	@Test("ED-133 Marking a child incomplete marks its completed parent incomplete too")
	func ed133() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- [x] A
			  - [x] A1
			  - [x] A2
			""")
		defer { deleteAccountManager(accountManager) }

		UncompleteCommand(actionName: "Uncomplete", undoManager: undoManager, delegate: self, outline: outline,
						  rows: [try outline.row(titled: "A1")], rowStrings: nil).execute()

		expectEdit(outline, before: """
			- [x] A
			  - [x] A1
			  - [x] A2
			""", after: """
			- A
			  - A1
			  - [x] A2
			""")
	}

	@Test("ED-136 With the filter on, completed rows are hidden together with their children; turning the filter off shows them again")
	func ed136() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - [x] A1
			  - A2
			- [x] B
			  - B1
			- C
			""")
		defer { deleteAccountManager(accountManager) }

		_ = outline.toggleFilterOn()
		#expect(visibleRows(outline) == ["A", "  A2", "C"])

		_ = outline.toggleFilterOn()
		#expect(visibleRows(outline) == ["A", "  A1", "  A2", "B", "  B1", "C"])

		// Hiding isn't deleting.
		expectOutline(outline, """
			- A
			  - [x] A1
			  - A2
			- [x] B
			  - B1
			- C
			""")
	}

	@Test("ED-137 Turn Filter On (Shift-Cmd-H) switches the Hide Completed and Hide Notes choices on and off together, without forgetting which ones were chosen")
	func ed137() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- [x] B
			""")
		defer { deleteAccountManager(accountManager) }

		// Both are chosen by default, and off until the filter is on.
		#expect(!outline.isCompletedFilterOn && !outline.isNotesFilterOn)
		_ = outline.toggleFilterOn()
		#expect(outline.isCompletedFilterOn && outline.isNotesFilterOn)

		// Unchoose Hide Completed; it stays unchosen when the filter goes off and on again.
		_ = outline.toggleCompletedFilter()
		#expect(!outline.isCompletedFilterOn && outline.isNotesFilterOn)
		#expect(visibleRows(outline) == ["A", "B"])
		_ = outline.toggleFilterOn()
		#expect(!outline.isCompletedFilterOn && !outline.isNotesFilterOn)
		_ = outline.toggleFilterOn()
		#expect(!outline.isCompletedFilterOn && outline.isNotesFilterOn)
		#expect(visibleRows(outline) == ["A", "B"])

		_ = outline.toggleCompletedFilter()
		#expect(visibleRows(outline) == ["A"])
	}

	// MARK: Helpers

	private func complete(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		CompleteCommand(actionName: "Complete", undoManager: undoManager, delegate: self, outline: outline,
						rows: rows, rowStrings: nil).execute()
	}

	/// The rows shown in the editor, indented by level.
	private func visibleRows(_ outline: Outline) -> [String] {
		(outline.shadowTable ?? []).map { String(repeating: "  ", count: $0.trueLevel) + ($0.topic?.string ?? "") }
	}
}

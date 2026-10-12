//
//  MoveRowBehaviors.swift
//  VinOutlineKitTests
//
//  ED-090 … ED-095: Moving rows up and down (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Moving rows up and down")
final class MoveRowBehaviors: VOKTestCase {

	@Test("ED-090 Move Up (Ctrl-Cmd-↑) swaps a row, with its children, with the sibling above it")
	func ed090() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			  - B1
			- C
			""")
		defer { deleteAccountManager(accountManager) }

		moveUp(["B"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			- B
			  - B1
			- C
			""", after: """
			- B
			  - B1
			- A
			  - A1
			- C
			""")
	}

	@Test("ED-091 Move Down (Ctrl-Cmd-↓) swaps a row, with its children, with the sibling below it")
	func ed091() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			  - B1
			- C
			  - C1
			""")
		defer { deleteAccountManager(accountManager) }

		moveDown(["B"], in: outline)

		expectEdit(outline, before: """
			- A
			- B
			  - B1
			- C
			  - C1
			""", after: """
			- A
			- C
			  - C1
			- B
			  - B1
			""")
	}

	@Test("ED-092 Move Up is unavailable for a first child and Move Down for a last child; rows never move to another parent this way")
	func ed092() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - A2
			- B
			""")
		defer { deleteAccountManager(accountManager) }
		let a1 = try outline.row(titled: "A1")
		let a2 = try outline.row(titled: "A2")

		#expect(outline.isMoveRowsUpUnavailable(rows: [a1]))
		#expect(!outline.isMoveRowsDownUnavailable(rows: [a1]))
		#expect(!outline.isMoveRowsUpUnavailable(rows: [a2]))
		#expect(outline.isMoveRowsDownUnavailable(rows: [a2]))
		#expect(outline.isMoveRowsUpUnavailable(rows: [try outline.row(titled: "A")]))
		#expect(outline.isMoveRowsDownUnavailable(rows: [try outline.row(titled: "B")]))

		// Moving the first child up anyway (no menu check) leaves it where it is.
		moveUp(["A1"], in: outline)
		expectOutline(outline, """
			- A
			  - A1
			  - A2
			- B
			""")
	}

	@Test("ED-093 Moving several adjacent siblings up or down moves them together, keeping their order")
	func ed093() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			- C
			- D
			""")
		defer { deleteAccountManager(accountManager) }

		moveUp(["B", "C"], in: outline)
		expectEdit(outline, before: """
			- A
			- B
			- C
			- D
			""", after: """
			- B
			- C
			- A
			- D
			""")

		undoManager.removeAllActions()
		moveDown(["B", "C"], in: outline)
		expectEdit(outline, before: """
			- B
			- C
			- A
			- D
			""", after: """
			- A
			- B
			- C
			- D
			""")
	}

	@Test("ED-094 Move Up/Down is unavailable when the selected rows have different parents")
	func ed094() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - A2
			- B
			- C
			""")
		defer { deleteAccountManager(accountManager) }
		let a2 = try outline.row(titled: "A2")
		let b = try outline.row(titled: "B")

		// Each row on its own could move.
		#expect(!outline.isMoveRowsUpUnavailable(rows: [a2]))
		#expect(!outline.isMoveRowsDownUnavailable(rows: [b]))

		#expect(outline.isMoveRowsUpUnavailable(rows: [a2, b]))
		#expect(outline.isMoveRowsDownUnavailable(rows: [a2, b]))
	}

	// MARK: Helpers

	private func moveUp(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		MoveRowUpCommand(actionName: "Move Up", undoManager: undoManager, delegate: self, outline: outline,
						 rows: rows, rowStrings: nil).execute()
	}

	private func moveDown(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		MoveRowDownCommand(actionName: "Move Down", undoManager: undoManager, delegate: self, outline: outline,
						   rows: rows, rowStrings: nil).execute()
	}
}

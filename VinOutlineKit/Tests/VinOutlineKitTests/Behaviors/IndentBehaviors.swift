//
//  IndentBehaviors.swift
//  VinOutlineKitTests
//
//  ED-010 … ED-022: Indent (Tab) and outdent (Shift-Tab).
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Indent / Outdent")
final class IndentBehaviors: VOKTestCase {

	// MARK: Indent

	@Test("ED-010 Indenting a row makes it the last child of the row above it, bringing its children along")
	func ed010() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- B
			  - B1
			- C
			""")
		defer { deleteAccountManager(accountManager) }

		indent(["B"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			- B
			  - B1
			- C
			""", after: """
			- A
			  - A1
			  - B
			    - B1
			- C
			""")
	}

	@Test("ED-011 Indenting the first row at its level does nothing, and Indent is unavailable for it")
	func ed011() async throws {
		let start = """
			- A
			  - A1
			  - A2
			- B
			"""
		let (outline, accountManager) = try await makeOutline(start)
		defer { deleteAccountManager(accountManager) }

		#expect(outline.isMoveRowsRightUnavailable(rows: [try outline.row(titled: "A")]))
		#expect(outline.isMoveRowsRightUnavailable(rows: [try outline.row(titled: "A1")]))
		#expect(!outline.isMoveRowsRightUnavailable(rows: [try outline.row(titled: "A2")]))

		indent(["A"], in: outline)
		expectOutline(outline, start)
		indent(["A1"], in: outline)
		expectOutline(outline, start)
	}

	@Test("ED-013 Indenting several adjacent rows makes them all children of the row above, in their original order")
	func ed013() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			- C
			- D
			""")
		defer { deleteAccountManager(accountManager) }

		indent(["C", "B"], in: outline)

		expectEdit(outline, before: """
			- A
			- B
			- C
			- D
			""", after: """
			- A
			  - B
			  - C
			- D
			""")
	}

	@Test("ED-014 Indenting a row under a collapsed row expands that row so the moved row stays visible")
	func ed014() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- (+) A
			  - A1
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		indent(["B"], in: outline)

		expectOutline(outline, """
			- A
			  - A1
			  - B
			""")
	}

	// MARK: Outdent

	@Test("ED-015 Outdenting a row moves it, with its children, to just after its parent; rows below it stay under the old parent")
	func ed015() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - A2
			    - A2a
			  - A3
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		outdent(["A2"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			  - A2
			    - A2a
			  - A3
			- B
			""", after: """
			- A
			  - A1
			  - A3
			- A2
			  - A2a
			- B
			""")
	}

	@Test("ED-016 Outdenting a top-level row does nothing, and Outdent is unavailable for it")
	func ed016() async throws {
		let start = """
			- A
			  - A1
			- B
			"""
		let (outline, accountManager) = try await makeOutline(start)
		defer { deleteAccountManager(accountManager) }

		#expect(outline.isMoveRowsLeftUnavailable(rows: [try outline.row(titled: "B")]))
		#expect(!outline.isMoveRowsLeftUnavailable(rows: [try outline.row(titled: "A1")]))

		outdent(["B"], in: outline)
		expectOutline(outline, start)
	}

	@Test("ED-017 Outdenting several sibling rows keeps their order, placed just after their old parent")
	func ed017() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			  - A2
			  - A3
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		outdent(["A2", "A3"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			  - A2
			  - A3
			- B
			""", after: """
			- A
			  - A1
			- A2
			- A3
			- B
			""")
	}

	@Test("ED-018 Outdenting a row together with one of its own children moves only the row; the child stays inside it")
	func ed018() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			    - A1a
			""")
		defer { deleteAccountManager(accountManager) }

		outdent(["A1", "A1a"], in: outline)

		expectEdit(outline, before: """
			- A
			  - A1
			    - A1a
			""", after: """
			- A
			- A1
			  - A1a
			""")
	}

	// MARK: Automatic completion

	@Test("ED-019 Indenting an incomplete row under a completed row marks that row incomplete")
	func ed019() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- [x] A
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		indent(["B"], in: outline)

		expectEdit(outline, before: """
			- [x] A
			- B
			""", after: """
			- A
			  - B
			""", knownUndoBug: "ZB-001 Undo doesn't reverse automatic completion changes made by indent")
	}

	@Test("ED-020 Indenting a completed row under an incomplete row whose children are then all complete marks that row complete")
	func ed020() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - [x] A1
			- [x] B
			""")
		defer { deleteAccountManager(accountManager) }

		indent(["B"], in: outline)

		expectEdit(outline, before: """
			- A
			  - [x] A1
			- [x] B
			""", after: """
			- [x] A
			  - [x] A1
			  - [x] B
			""", knownUndoBug: "ZB-001 Undo doesn't reverse automatic completion changes made by indent")
	}

	@Test("ED-021 Outdenting the last incomplete child of a row whose other children are complete marks that row complete")
	func ed021() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - [x] A1
			  - A2
			""")
		defer { deleteAccountManager(accountManager) }

		outdent(["A2"], in: outline)

		expectEdit(outline, before: """
			- A
			  - [x] A1
			  - A2
			""", after: """
			- [x] A
			  - [x] A1
			- A2
			""")
	}

	// MARK: Text being edited

	@Test("ED-022 Indenting while editing a row keeps its new text; undo restores both the position and the earlier text")
	func ed022() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			- B
			""")
		defer { deleteAccountManager(accountManager) }

		let b = try outline.row(titled: "B")
		MoveRowRightCommand(actionName: "Indent", undoManager: undoManager, delegate: self, outline: outline,
							rows: [b], rowStrings: .topic(NSAttributedString(string: "B edited"))).execute()

		expectEdit(outline, before: """
			- A
			- B
			""", after: """
			- A
			  - B edited
			""")
	}

	// MARK: Helpers

	private func indent(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		let rows = titles.compactMap { try? outline.row(titled: $0, sourceLocation: sourceLocation) }
		MoveRowRightCommand(actionName: "Indent", undoManager: undoManager, delegate: self, outline: outline,
							rows: rows, rowStrings: nil).execute()
	}

	private func outdent(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		let rows = titles.compactMap { try? outline.row(titled: $0, sourceLocation: sourceLocation) }
		MoveRowLeftCommand(actionName: "Outdent", undoManager: undoManager, delegate: self, outline: outline,
						   rows: rows, rowStrings: nil).execute()
	}

}

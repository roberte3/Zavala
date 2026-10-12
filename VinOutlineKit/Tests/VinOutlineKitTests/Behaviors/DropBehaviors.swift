//
//  DropBehaviors.swift
//  VinOutlineKitTests
//
//  ED-190 … ED-194: Drag and drop (model level).
//  A test can't perform a real drag, so these run the commands the editor's drop delegate runs
//  (EditorViewController+Drop.swift), with the destination it computes for each kind of drop.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Drag and drop")
final class DropBehaviors: VOKTestCase {

	@Test("ED-190 Dragging rows between two rows moves them, with children, to that position")
	func ed190() async throws {
		let original = """
			- A
			  - A1
			  - A2
			- B
			- C
			  - C1
			"""

		// Up, between A and B: the editor drops after A, in A's parent.
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		drop(["C"], in: outline, toParent: outline, at: 1)
		expectEdit(outline, before: original, after: """
			- A
			  - A1
			  - A2
			- C
			  - C1
			- B
			""")

		// Into another parent, between A1 and A2.
		let (other, otherManager) = try await makeOutline(original)
		defer { deleteAccountManager(otherManager) }
		undoManager.removeAllActions()
		drop(["C"], in: other, toParent: try other.row(titled: "A"), at: 1)
		expectEdit(other, before: original, after: """
			- A
			  - A1
			  - C
			    - C1
			  - A2
			- B
			""")
	}

	@Test("ED-191 Dropping rows onto a row makes them its first children")
	func ed191() async throws {
		let original = """
			- A
			  - A1
			- B
			- C
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		drop(["B", "C"], in: outline, toParent: try outline.row(titled: "A"), at: 0)

		expectEdit(outline, before: original, after: """
			- A
			  - B
			  - C
			  - A1
			""")
	}

	@Test("ED-192 Dropping rows onto themselves or their own descendants does nothing")
	func ed192() async throws {
		let original = """
			- A
			  - A1
			    - A1a
			- B
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		drop(["A"], in: outline, toParent: try outline.row(titled: "A"), at: 0)
		expectOutline(outline, original)
		drop(["A"], in: outline, toParent: try outline.row(titled: "A1a"), at: 0)
		expectOutline(outline, original)
	}

	@Test("ED-193 Dropping rows from another outline copies them into this outline; the source outline is unchanged")
	func ed193() async throws {
		let sourceDSL = """
			- X
			  > x note
			  - X1
			- [x] Y
			"""
		let original = """
			- A
			- B
			"""
		let (source, sourceManager) = try await makeOutline(sourceDSL)
		defer { deleteAccountManager(sourceManager) }

		// Between A and B: the editor passes the row above as afterRow.
		let (between, betweenManager) = try await makeOutline(original)
		defer { deleteAccountManager(betweenManager) }
		RemoteDropRowCommand(actionName: "Copy", undoManager: undoManager, delegate: self, outline: between,
							 rowGroups: source.rows.map(RowGroup.init), afterRow: try between.row(titled: "A"),
							 prefersEnd: false, afterRowIsNewParent: false).execute()
		expectEdit(between, before: original, after: """
			- A
			- X
			  > x note
			  - X1
			- [x] Y
			- B
			""")

		// Onto B: B becomes their parent.
		let (onto, ontoManager) = try await makeOutline(original)
		defer { deleteAccountManager(ontoManager) }
		undoManager.removeAllActions()
		RemoteDropRowCommand(actionName: "Copy", undoManager: undoManager, delegate: self, outline: onto,
							 rowGroups: source.rows.map(RowGroup.init), afterRow: try onto.row(titled: "B"),
							 prefersEnd: false, afterRowIsNewParent: true).execute()
		expectEdit(onto, before: original, after: """
			- A
			- B
			  - X
			    > x note
			    - X1
			  - [x] Y
			""")

		expectOutline(source, sourceDSL)
	}

	@Test("ED-194 Undo of a drop restores both the source and destination positions")
	func ed194() async throws {
		// Rows from two different parents, dropped together under a third.
		let original = """
			- A
			  - A1
			  - A2
			- B
			  - B1
			- C
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		drop(["A2", "B1"], in: outline, toParent: try outline.row(titled: "C"), at: 0)

		expectEdit(outline, before: original, after: """
			- A
			  - A1
			- B
			- C
			  - A2
			  - B1
			""")
	}

	// MARK: Helpers

	/// What a drop of rows from this outline does once the editor has worked out the destination.
	private func drop(_ titles: [String], in outline: Outline, toParent: RowContainer, at index: Int, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let rows = try? titles.map({ try outline.row(titled: $0, sourceLocation: sourceLocation) }) else { return }
		LocalDropRowCommand(actionName: "Move", undoManager: undoManager, delegate: self, outline: outline,
							rows: rows, toParent: toParent, toChildIndex: index).execute()
	}
}

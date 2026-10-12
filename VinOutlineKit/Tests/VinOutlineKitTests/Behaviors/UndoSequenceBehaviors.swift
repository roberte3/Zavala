//
//  UndoSequenceBehaviors.swift
//  VinOutlineKitTests
//
//  ED-250 … ED-251: undo and redo across a run of mixed edits.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Undo / redo across several edits")
final class UndoSequenceBehaviors: VOKTestCase {

	@Test("ED-250 A sequence of mixed edits (create, type, indent, move, complete, delete) undoes step by step back to the exact original outline")
	func ed250() async throws {
		let (outline, accountManager) = try await makeOutline(Self.start)
		defer { deleteAccountManager(accountManager) }

		let states = runMixedEdits(on: outline)

		for state in states.dropLast().reversed() {
			undoManager.undo()
			expectOutline(outline, state)
		}
		expectOutline(outline, Self.start)
	}

	@Test("ED-251 After undoing a sequence, redo re-applies each step in order, ending at the exact edited outline")
	func ed251() async throws {
		let (outline, accountManager) = try await makeOutline(Self.start)
		defer { deleteAccountManager(accountManager) }

		let states = runMixedEdits(on: outline)

		for _ in states.dropFirst() {
			undoManager.undo()
		}
		expectOutline(outline, Self.start)

		for state in states.dropFirst() {
			undoManager.redo()
			expectOutline(outline, state)
		}
	}

	// MARK: Sequence

	private static let start = """
		- A
		  - A1
		- B
		- C
		  - C1
		  - C2
		"""

	/// Runs seven edits, one command each, and checks the outline after each one.
	/// Returns the outline after every step, starting with the original, so undo and redo can be checked step by step.
	private func runMixedEdits(on outline: Outline) -> [String] {
		var states = [Self.start]
		// Without a run loop, automatic grouping would merge every edit into one undo step.
		undoManager.groupsByEvent = false

		// Each edit gets its own undo group, as one key press does in the app.
		func step(_ expected: String, _ edit: () -> Void) {
			undoManager.beginUndoGrouping()
			edit()
			undoManager.endUndoGrouping()
			expectOutline(outline, expected)
			states.append(expected)
		}

		// Type: rename B
		step("""
			- A
			  - A1
			- B edited
			- C
			  - C1
			  - C2
			""") {
			typeText("B edited", into: "B", in: outline)
		}

		// Create: an empty row after C1
		step("""
			- A
			  - A1
			- B edited
			- C
			  - C1
			  -
			  - C2
			""") {
			createRow(after: "C1", in: outline)
		}

		// Indent: B edited goes under A
		step("""
			- A
			  - A1
			  - B edited
			- C
			  - C1
			  -
			  - C2
			""") {
			indent(["B edited"], in: outline)
		}

		// Move: A (with its children) goes below C
		step("""
			- C
			  - C1
			  -
			  - C2
			- A
			  - A1
			  - B edited
			""") {
			moveDown(["A"], in: outline)
		}

		// Complete: C1
		step("""
			- C
			  - [x] C1
			  -
			  - C2
			- A
			  - A1
			  - B edited
			""") {
			complete(["C1"], in: outline)
		}

		// Delete: B edited
		step("""
			- C
			  - [x] C1
			  -
			  - C2
			- A
			  - A1
			""") {
			delete(["B edited"], in: outline)
		}

		// Outdent: C2 moves out of C, just after it
		step("""
			- C
			  - [x] C1
			  -
			- C2
			- A
			  - A1
			""") {
			outdent(["C2"], in: outline)
		}

		return states
	}

	// MARK: Helpers

	private func typeText(_ text: String, into title: String, in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let row = try? outline.row(titled: title, sourceLocation: sourceLocation) else { return }
		TextChangedCommand(actionName: "Typing", undoManager: undoManager, delegate: self, outline: outline,
						   row: row, rowStrings: .topic(NSAttributedString(string: text)),
						   isInNotes: false, selection: NSRange(location: text.count, length: 0)).execute()
	}

	private func createRow(after title: String, in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let row = try? outline.row(titled: title, sourceLocation: sourceLocation) else { return }
		CreateRowAfterCommand(actionName: "Add Row", undoManager: undoManager, delegate: self, outline: outline,
							  afterRow: row, rowStrings: nil, childRowIndent: true).execute()
	}

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

	private func moveDown(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		let rows = titles.compactMap { try? outline.row(titled: $0, sourceLocation: sourceLocation) }
		MoveRowDownCommand(actionName: "Move Down", undoManager: undoManager, delegate: self, outline: outline,
						   rows: rows, rowStrings: nil).execute()
	}

	private func complete(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		let rows = titles.compactMap { try? outline.row(titled: $0, sourceLocation: sourceLocation) }
		CompleteCommand(actionName: "Complete", undoManager: undoManager, delegate: self, outline: outline,
						rows: rows, rowStrings: nil).execute()
	}

	private func delete(_ titles: [String], in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		let rows = titles.compactMap { try? outline.row(titled: $0, sourceLocation: sourceLocation) }
		DeleteRowCommand(actionName: "Delete Rows", undoManager: undoManager, delegate: self, outline: outline,
						 rows: rows, currentRow: nil, rowStrings: nil, isInOutlineMode: true).execute()
	}
}

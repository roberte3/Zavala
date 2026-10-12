//
//  DeleteRowEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level delete behaviors (L2): Delete in an empty row, Delete Rows, Delete Completed Rows,
//  and where the cursor or selection ends up. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Deleting rows in the editor", .serialized)
struct DeleteRowEditorBehaviors {

	@Test("ED-070 Delete in an empty row without children deletes the row and puts the cursor at the end of the row above")
	func ed070() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			-
			- Bravo
			""")
		try await editor.placeCursor(in: "", at: 0)

		try await editor.deleteBackward()

		#expect(editor.cursorDescription == "\"Alpha\" @ 5")
		expectUndoRedo(editor, before: """
			- Alpha
			-
			- Bravo
			""", after: """
			- Alpha
			- Bravo
			""")
		await editor.close()

		// The row above on screen is the previous sibling's last child.
		let nephew = try await EditorHarness.open("""
			- Alpha
			  - A1
			-
			""")
		try await nephew.placeCursor(in: "", at: 0)
		try await nephew.deleteBackward()
		#expect(nephew.cursorDescription == "\"A1\" @ 2")
		expectOutline(nephew.outline, """
			- Alpha
			  - A1
			""")
		await nephew.close()
	}

	@Test("ED-071 Delete in an empty row that has children does nothing")
	func ed071() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			-
			  - E1
			""")
		try await editor.placeCursor(in: "", at: 0)

		try await editor.deleteBackward()

		#expect(editor.cursorDescription == "\"\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			  - A1
			-
			  - E1
			""", after: """
			- Alpha
			  - A1
			-
			  - E1
			""")
		await editor.close()
	}

	@Test("ED-072 Delete Rows (Shift-Cmd-Delete) deletes the selected rows together with all their children")
	func ed072() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			  - B1
			    - B1a
			- Charlie
			- Delta
			""")
		try await editor.selectRows(["Bravo", "Delta"])

		try await editor.pressMenu(UIKeyCommand.inputDelete, [.shift, .command])

		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			  - B1
			    - B1a
			- Charlie
			- Delta
			""", after: """
			- Alpha
			- Charlie
			""")
		await editor.close()
	}

	@Test("ED-074 Deleting rows in row-selection mode selects the row now in the first deleted row's place, or the last row if none")
	func ed074() async throws {
		let middle = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			""")
		try await middle.selectRows(["Bravo"])
		try await middle.pressMenu(UIKeyCommand.inputDelete, [.shift, .command])
		#expect(middle.selectedTitles == ["Charlie"])
		await middle.close()

		let last = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			""")
		try await last.selectRows(["Charlie"])
		try await last.pressMenu(UIKeyCommand.inputDelete, [.shift, .command])
		#expect(last.selectedTitles == ["Bravo"])
		await last.close()

		let several = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			- Delta
			""")
		try await several.selectRows(["Alpha", "Charlie"])
		try await several.pressMenu(UIKeyCommand.inputDelete, [.shift, .command])
		withKnownIssue("ZB-007 After deleting several rows, the selection lands at a different place from run to run", isIntermittent: true) {
			#expect(several.selectedTitles == ["Bravo"])
		}
		await several.close()
	}

	@Test("ED-075 Delete Completed Rows (Cmd-D) deletes every completed row in the outline, with their children, after a confirmation unless confirmation was turned off")
	func ed075() async throws {
		let originalConfirm = AppDefaults.shared.confirmDeleteCompletedRows
		defer { AppDefaults.shared.confirmDeleteCompletedRows = originalConfirm }
		let outline = """
			- Alpha
			  - [x] A1
			- [x] Bravo
			  - B1
			- Charlie
			"""

		AppDefaults.shared.confirmDeleteCompletedRows = false
		let editor = try await EditorHarness.open(outline)
		try await editor.placeCursor(in: "Charlie", at: 0)
		try await editor.pressMenu("d", .command)
		let after = """
			- Alpha
			- Charlie
			"""
		expectOutline(editor.outline, after)
		// Restoring the rows runs automatic completion on their parents, and undo doesn't put it back.
		editor.editor.undoManager?.undo()
		withKnownIssue("ZB-006 Undo of a delete changes the completion of the restored rows' parents") {
			expectOutline(editor.outline, outline)
		}
		editor.editor.undoManager?.redo()
		withKnownIssue("ZB-006 Undo of a delete changes the completion of the restored rows' parents") {
			expectOutline(editor.outline, after)
		}
		await editor.close()

		AppDefaults.shared.confirmDeleteCompletedRows = true
		let confirming = try await EditorHarness.open(outline)
		try await confirming.placeCursor(in: "Charlie", at: 0)
		try await confirming.pressMenu("d", .command)
		let alert = confirming.editor.presentedViewController as? UIAlertController
		#expect(alert?.title == String.deleteCompletedRowsTitle)
		#expect(alert?.actions.map(\.title) == [String.deleteAlwaysControlLabel, String.deleteOnceControlLabel, String.cancelControlLabel])
		expectOutline(confirming.outline, outline)
		confirming.editor.dismiss(animated: false)
		await confirming.close()
	}
}

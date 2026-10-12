//
//  SplitJoinEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level split and join behaviors (L2): what Return in the middle of a row, Shift-Option-Return,
//  and Delete at the start of a row do, and where the cursor ends up. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Split and join in the editor", .serialized)
struct SplitJoinEditorBehaviors {

	@Test("ED-050 Return in the middle of a row's text splits it: text after the cursor moves to a new row just below, and the cursor goes to the start of that row")
	func ed050() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)

		try await editor.type("\n")

		#expect(editor.cursorDescription == "\"pha\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Al
			- pha
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-053 Shift-Option-Return splits at the cursor like Return; at the very start of the row it creates an empty row above without moving the cursor")
	func ed053() async throws {
		let middle = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await middle.placeCursor(in: "Alpha", at: 2)
		try await middle.press("\r", [.shift, .alternate])
		#expect(middle.cursorDescription == "\"pha\" @ 0")
		expectUndoRedo(middle, before: """
			- Alpha
			- Bravo
			""", after: """
			- Al
			- pha
			- Bravo
			""")
		await middle.close()

		let start = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await start.placeCursor(in: "Bravo", at: 0)
		try await start.press("\r", [.shift, .alternate])
		#expect(start.cursorDescription == "\"Bravo\" @ 0")
		expectUndoRedo(start, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await start.close()
	}

	@Test("ED-054 Delete at the start of a row joins its text onto the end of the row above, when that row is its previous sibling")
	func ed054() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			  - A2
			- Bravo
			""")
		try await editor.placeCursor(in: "A2", at: 0)

		try await editor.deleteBackward()

		expectUndoRedo(editor, before: """
			- Alpha
			  - A1
			  - A2
			- Bravo
			""", after: """
			- Alpha
			  - A1A2
			- Bravo
			""")
		await editor.close()

		// A collapsed sibling is the row above, so the row joins onto it; its hidden children are untouched.
		let collapsed = try await EditorHarness.open("""
			- (+) Alpha
			  - A1
			- Bravo
			""")
		try await collapsed.placeCursor(in: "Bravo", at: 0)

		try await collapsed.deleteBackward()

		expectUndoRedo(collapsed, before: """
			- (+) Alpha
			  - A1
			- Bravo
			""", after: """
			- (+) AlphaBravo
			  - A1
			""")
		await collapsed.close()
	}

	@Test("ED-055 Delete at the start of a row does nothing when the row above is not its sibling (e.g. it is the parent)")
	func ed055() async throws {
		let firstChild = try await EditorHarness.open("""
			- Alpha
			  - A1
			""")
		try await firstChild.placeCursor(in: "A1", at: 0)
		try await firstChild.deleteBackward()
		#expect(firstChild.cursorDescription == "\"A1\" @ 0")
		expectUndoRedo(firstChild, before: """
			- Alpha
			  - A1
			""", after: """
			- Alpha
			  - A1
			""")
		await firstChild.close()

		// The previous sibling's children are showing, so the row above is one of them.
		let nephewAbove = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await nephewAbove.placeCursor(in: "Bravo", at: 0)
		try await nephewAbove.deleteBackward()
		#expect(nephewAbove.cursorDescription == "\"Bravo\" @ 0")
		expectUndoRedo(nephewAbove, before: """
			- Alpha
			  - A1
			- Bravo
			""", after: """
			- Alpha
			  - A1
			- Bravo
			""")
		await nephewAbove.close()
	}

	@Test("ED-056 Rows with children are never joined into the row above; Delete at their start does nothing")
	func ed056() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			  - B1
			""")
		try await editor.placeCursor(in: "Bravo", at: 0)

		try await editor.deleteBackward()

		#expect(editor.cursorDescription == "\"Bravo\" @ 0")
		expectOutline(editor.outline, """
			- Alpha
			- Bravo
			  - B1
			""")
		// Zavala still records a join it didn't make, and undoing it inserts the row a second time.
		editor.editor.undoManager?.undo()
		withKnownIssue("ZB-003 Undo after Delete at the start of a row with children duplicates the row") {
			expectOutline(editor.outline, """
				- Alpha
				- Bravo
				  - B1
				""")
		}
		await editor.close()
	}

	@Test("ED-057 After a join, the cursor sits at the join point")
	func ed057() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 0)

		try await editor.deleteBackward()

		#expect(editor.cursorDescription == "\"AlphaBravo\" @ 5")
		await editor.close()
	}
}

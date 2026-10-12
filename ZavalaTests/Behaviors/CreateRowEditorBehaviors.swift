//
//  CreateRowEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level create-row behaviors (L2): what Return, Shift-Return, and the Add Row menu
//  commands do, and where the cursor ends up. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Creating rows in the editor", .serialized)
struct CreateRowEditorBehaviors {

	@Test("ED-030 Return at the end of a row creates an empty row just below it at the same level, and the cursor moves into it")
	func ed030() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 5)

		try await editor.type("\n")

		#expect(editor.cursorDescription == "\"\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-033 With the \"create rows at same level\" setting, Return at the end of a row with showing children creates a sibling instead of a first child")
	func ed033() async throws {
		let original = AppDefaults.shared.createRows
		AppDefaults.shared.createRows = .atSameLevel
		defer { AppDefaults.shared.createRows = original }

		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 5)

		try await editor.type("\n")

		expectUndoRedo(editor, before: """
			- Alpha
			  - A1
			- Bravo
			""", after: """
			- Alpha
			  - A1
			-
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-034 Return at the start of a row that has text creates an empty row above it; the cursor stays in the original row")
	func ed034() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 0)

		try await editor.type("\n")

		#expect(editor.cursorDescription == "\"Bravo\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-035 Return in an empty row that is the last child of its parent outdents it instead of creating a row")
	func ed035() async throws {
		// The usual way to get there: Return at the end of the last child, then Return again.
		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await editor.placeCursor(in: "A1", at: 2)
		try await editor.type("\n")
		expectOutline(editor.outline, """
			- Alpha
			  - A1
			  -
			- Bravo
			""")

		try await editor.type("\n")

		#expect(editor.cursorDescription == "\"\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			  - A1
			  -
			- Bravo
			""", after: """
			- Alpha
			  - A1
			-
			- Bravo
			""")
		await editor.close()

		// A last child that became empty because its text was deleted.
		let emptied = try await EditorHarness.open("""
			- Alpha
			  - A1
			  - x
			- Bravo
			""")
		try await emptied.placeCursor(in: "x", at: 1)
		try await emptied.deleteBackward()
		try await emptied.type("\n")
		withKnownIssue("ZB-002 Return in a last child that was emptied by deleting its text creates a row above instead of outdenting") {
			expectOutline(emptied.outline, """
				- Alpha
				  - A1
				-
				- Bravo
				""")
		}
		await emptied.close()
	}

	@Test("ED-036 Return in an empty row that is not the last child (or is top-level) creates an empty row above it")
	func ed036() async throws {
		let notLast = try await EditorHarness.open("""
			- Alpha
			  -
			  - A2
			""")
		try await notLast.placeCursor(in: "", at: 0)
		try await notLast.type("\n")
		expectUndoRedo(notLast, before: """
			- Alpha
			  -
			  - A2
			""", after: """
			- Alpha
			  -
			  -
			  - A2
			""")
		await notLast.close()

		let topLevel = try await EditorHarness.open("""
			- Alpha
			-
			""")
		try await topLevel.placeCursor(in: "", at: 0)
		try await topLevel.type("\n")
		expectUndoRedo(topLevel, before: """
			- Alpha
			-
			""", after: """
			- Alpha
			-
			-
			""")
		await topLevel.close()
	}

	@Test("ED-037 Shift-Return creates an empty row above the current row and moves the cursor into it")
	func ed037() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.press("\r", .shift)

		#expect(editor.cursorDescription == "\"\" @ 0")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-038 Add Row Below (Ctrl-Return) creates an empty row below the current row and Add Row Above (Shift-Return) one above; both move the cursor into it")
	func ed038() async throws {
		let below = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await below.placeCursor(in: "Alpha", at: 2)
		try await below.pressMenu("\n", .control)
		#expect(below.cursorDescription == "\"\" @ 0")
		expectUndoRedo(below, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await below.close()

		let above = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await above.placeCursor(in: "Bravo", at: 2)
		try await above.pressMenu("\n", .shift)
		#expect(above.cursorDescription == "\"\" @ 0")
		expectUndoRedo(above, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			-
			- Bravo
			""")
		await above.close()
	}

	@Test("ED-039 Add Row Inside (Cmd-}) creates an empty first child of the current row, expanding it if collapsed, and moves the cursor into it")
	func ed039() async throws {
		let editor = try await EditorHarness.open("""
			- (+) Alpha
			  - A1
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 5)

		try await editor.pressMenu("}", .command)

		#expect(editor.cursorDescription == "\"\" @ 0")
		expectUndoRedo(editor, before: """
			- (+) Alpha
			  - A1
			- Bravo
			""", after: """
			- Alpha
			  -
			  - A1
			- Bravo
			""")
		await editor.close()
	}
}

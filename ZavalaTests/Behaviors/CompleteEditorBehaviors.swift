//
//  CompleteEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level completion behaviors (L2): Cmd-Return on the current or selected rows, and where the
//  cursor goes when completed rows are hidden. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Completing rows in the editor", .serialized)
struct CompleteEditorBehaviors {

	@Test("ED-130 Complete (Cmd-Return) marks the current row complete; pressing it again marks it incomplete")
	func ed130() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.pressMenu("\n", .command)
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			- [x] Bravo
			""")

		try await editor.pressMenu("\n", .command)
		expectUndoRedo(editor, before: """
			- Alpha
			- [x] Bravo
			""", after: """
			- Alpha
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-134 With several rows selected, Complete marks them all complete if any is incomplete; otherwise it marks them all incomplete")
	func ed134() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- [x] Bravo
			- Charlie
			""")
		try await editor.selectRows(["Alpha", "Bravo"])

		try await editor.pressMenu("\n", .command)
		expectOutline(editor.outline, """
			- [x] Alpha
			- [x] Bravo
			- Charlie
			""")
		editor.editor.undoManager?.undo()
		withKnownIssue("ZB-009 Undo of Complete marks every selected row incomplete, even rows that were already complete") {
			expectOutline(editor.outline, """
				- Alpha
				- [x] Bravo
				- Charlie
				""")
		}
		editor.editor.undoManager?.redo()
		expectOutline(editor.outline, """
			- [x] Alpha
			- [x] Bravo
			- Charlie
			""")

		try await editor.pressMenu("\n", .command)
		expectUndoRedo(editor, before: """
			- [x] Alpha
			- [x] Bravo
			- Charlie
			""", after: """
			- Alpha
			- Bravo
			- Charlie
			""")
		await editor.close()
	}

	@Test("ED-135 With completed rows hidden, completing the current row hides it and moves the cursor to the row above")
	func ed135() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			""")
		try await editor.pressMenu("h", [.shift, .command])
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.pressMenu("\n", .command)

		#expect(editor.cursorDescription == "\"Alpha\" @ 5")
		#expect(editor.outline.shadowTable?.map { $0.topic?.string ?? "" } == ["Alpha", "Charlie"])
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			- Charlie
			""", after: """
			- Alpha
			- [x] Bravo
			- Charlie
			""")
		await editor.close()
	}
}

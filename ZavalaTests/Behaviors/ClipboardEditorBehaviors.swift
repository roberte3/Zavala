//
//  ClipboardEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level cut, copy, and paste behaviors (L2), through the system clipboard.
//  These overwrite whatever is on the clipboard (decided 2026-10-09). Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Cut, copy, paste in the editor", .serialized)
struct ClipboardEditorBehaviors {

	private let copy = #selector(UIResponderStandardEditActions.copy(_:))
	private let cut = #selector(UIResponderStandardEditActions.cut(_:))

	@Test("ED-170 Copying selected rows copies them with all their children, notes, and completion")
	func ed170() async throws {
		EditorHarness.clearClipboard()
		defer { EditorHarness.clearClipboard() }
		let original = """
			- Alpha
			- [x] Bravo
			  > b note
			  - B1
			  - [x] B2
			- Charlie
			"""
		let editor = try await EditorHarness.open(original)
		try await editor.selectRows(["Bravo"])

		try await editor.edit(copy)
		expectOutline(editor.outline, original)

		try await editor.selectRows(["Charlie"])
		try await editor.pasteAndWait()

		expectUndoRedo(editor, before: original, after: """
			- Alpha
			- [x] Bravo
			  > b note
			  - B1
			  - [x] B2
			- Charlie
			- [x] Bravo
			  > b note
			  - B1
			  - [x] B2
			""")
		await editor.close()
	}

	@Test("ED-171 Cutting selected rows removes them (with children) and puts them on the clipboard; undo restores them")
	func ed171() async throws {
		EditorHarness.clearClipboard()
		defer { EditorHarness.clearClipboard() }
		let original = """
			- Alpha
			- Bravo
			  - B1
			- Charlie
			- Delta
			"""
		let editor = try await EditorHarness.open(original)
		try await editor.selectRows(["Bravo", "Charlie"])

		try await editor.edit(cut)
		let afterCut = """
			- Alpha
			- Delta
			"""
		expectOutline(editor.outline, afterCut)
		editor.editor.undoManager?.undo()
		withKnownIssue("ZB-011 Undo of Cut puts a row back at the end of its level when the row above it was another row's child") {
			expectOutline(editor.outline, original)
		}
		editor.editor.undoManager?.redo()
		expectOutline(editor.outline, afterCut)

		try await editor.selectRows(["Delta"])
		try await editor.pasteAndWait()
		expectOutline(editor.outline, """
			- Alpha
			- Delta
			- Bravo
			  - B1
			- Charlie
			""")
		await editor.close()
	}

	@Test("ED-173 Pasting plain text with several lines while editing a row's text inserts it as text in that row, not as new rows")
	func ed173() async throws {
		EditorHarness.clearClipboard()
		defer { EditorHarness.clearClipboard() }
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)
		UIPasteboard.general.string = "one\ntwo"

		try await editor.edit(#selector(UIResponderStandardEditActions.paste(_:)))
		try await editor.commitTyping()

		// The system's smart paste adds a space on each side. A topic with a line break can't be written
		// in the outline DSL, so compare the topics directly.
		#expect(editor.outline.rows.map { $0.topic?.string ?? "" } == ["Al one\ntwo pha", "Bravo"])
		#expect(editor.outline.rows.allSatisfy { $0.rows.isEmpty })
		await editor.close()
	}
}

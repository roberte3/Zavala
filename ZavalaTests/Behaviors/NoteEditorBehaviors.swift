//
//  NoteEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level note and in-row text behaviors (L2): Add Note, moving between topic and note,
//  Delete in an empty note, Option-Return, Option-Tab, and Hide Notes. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Notes in the editor", .serialized)
struct NoteEditorBehaviors {

	@Test("ED-150 Add Note (Ctrl--) gives the current row an empty note and moves the cursor into it")
	func ed150() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.pressMenu("-", .control)

		#expect(editor.cursorDescription == "\"Bravo\" @ 0 (note)")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			- Bravo
			  >
			""")
		await editor.close()
	}

	@Test("ED-151 Ctrl-- on a row that already has a note moves the cursor between its topic and its note")
	func ed151() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  > a note
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)

		try await editor.pressMenu("-", .control)
		#expect(editor.cursorDescription == "\"Alpha\" @ 6 (note)")

		try await editor.pressMenu("-", .control)
		#expect(editor.cursorDescription == "\"Alpha\" @ 5")

		expectOutline(editor.outline, """
			- Alpha
			  > a note
			""")
		await editor.close()
	}

	@Test("ED-153 Delete in an empty note removes the note and moves the cursor back to the topic")
	func ed153() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)
		try await editor.pressMenu("-", .control)
		expectOutline(editor.outline, """
			- Alpha
			- Bravo
			  >
			""")

		try await editor.deleteBackward()

		#expect(editor.cursorDescription == "\"Bravo\" @ 5")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			  >
			""", after: """
			- Alpha
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-154 Option-Return in a topic inserts a line break inside the row instead of creating a row")
	func ed154() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)

		try await editor.press("\r", .alternate)
		try await editor.commitTyping()

		// A topic with a line break can't be written in the outline DSL, so compare the topics directly.
		#expect(topics(editor.outline) == ["Al\npha", "Bravo"])
		#expect(editor.cursorDescription == "\"Al\npha\" @ 3")
		editor.editor.undoManager?.undo()
		#expect(topics(editor.outline) == ["Alpha", "Bravo"])
		editor.editor.undoManager?.redo()
		#expect(topics(editor.outline) == ["Al\npha", "Bravo"])
		await editor.close()
	}

	@Test("ED-155 Option-Tab inserts a tab character instead of indenting")
	func ed155() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.press("\t", .alternate)
		try await editor.commitTyping()

		#expect(editor.cursorDescription == "\"Br\tavo\" @ 3")
		expectUndoRedo(editor, before: """
			- Alpha
			- Bravo
			""", after: """
			- Alpha
			- Br\tavo
			""")
		await editor.close()
	}

	@Test("ED-156 Hide Notes hides note text in the editor without deleting it")
	func ed156() async throws {
		let original = """
			- Alpha
			  > a note
			- Bravo
			"""
		let editor = try await EditorHarness.open(original)
		#expect(try editor.isNoteShown(for: "Alpha"))

		// Turn Filter On; Hide Notes is chosen by default (ED-137).
		try await editor.pressMenu("h", [.shift, .command])
		#expect(try editor.isNoteShown(for: "Alpha") == false)
		expectOutline(editor.outline, original)

		try await editor.pressMenu("h", [.shift, .command])
		#expect(try editor.isNoteShown(for: "Alpha"))
		await editor.close()
	}

	private func topics(_ outline: Outline) -> [String] {
		var result = [String]()
		func visit(_ row: Row) {
			result.append(row.topic?.string ?? "")
			row.rows.forEach(visit)
		}
		outline.rows.forEach(visit)
		return result
	}
}

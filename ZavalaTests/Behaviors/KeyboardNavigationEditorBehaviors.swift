//
//  KeyboardNavigationEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level keyboard navigation and focus behaviors (L2): moving the cursor between rows with arrows and
//  Ctrl-P/N, the edges of the outline, Esc between text and row selection, which keys Tab is offered for, and
//  Focus In/Out. Model-level focus is in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Keyboard navigation and focus in the editor", .serialized)
struct KeyboardNavigationEditorBehaviors {

	@Test("ED-230 Down arrow on a row's last line moves the cursor to the next visible row, keeping roughly the same horizontal position")
	func ed230() async throws {
		let editor = try await EditorHarness.open("""
			- Alphabet
			- Hi
			- Charlietown
			""")
		try await editor.placeCursor(in: "Alphabet", at: 4)

		try await editor.press("n", .control)
		#expect(editor.cursorDescription == "\"Hi\" @ 2")

		// "Hi" is too short to keep column 4, but the column is remembered for the next row.
		try await editor.press("n", .control)
		#expect(editor.cursorDescription == "\"Charlietown\" @ 4")
		await editor.close()
	}

	@Test("ED-231 Up arrow on a row's first line moves the cursor to the previous visible row, keeping roughly the same horizontal position")
	func ed231() async throws {
		let editor = try await EditorHarness.open("""
			- Charlietown
			- Hi
			- Alphabet
			""")
		try await editor.placeCursor(in: "Alphabet", at: 4)

		try await editor.press("p", .control)
		#expect(editor.cursorDescription == "\"Hi\" @ 2")

		try await editor.press("p", .control)
		#expect(editor.cursorDescription == "\"Charlietown\" @ 4")
		await editor.close()
	}

	@Test("ED-232 Ctrl-P and Ctrl-N move the cursor up and down a row, like the arrows")
	func ed232() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			""")
		try await editor.placeCursor(in: "Bravo", at: 2)

		try await editor.press("n", .control)
		#expect(editor.cursorDescription == "\"Charlie\" @ 2")

		try await editor.press("p", .control)
		#expect(editor.cursorDescription == "\"Bravo\" @ 2")

		try await editor.press("p", .control)
		#expect(editor.cursorDescription == "\"Alpha\" @ 2")
		await editor.close()
	}

	@Test("ED-233 Up from the first row moves the cursor to the tags field")
	func ed233() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)

		try await editor.press("p", .control)
		try await editor.waitUntil("the tags field has keyboard focus") {
			editor.isTagFieldFocused
		}
		await editor.close()
	}

	@Test("ED-234 Down from the last row moves the cursor to the end of that row")
	func ed234() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 0)

		try await editor.press("n", .control)
		#expect(editor.cursorDescription == "\"Bravo\" @ 5")
		await editor.close()
	}

	@Test("ED-235 Navigation skips rows hidden inside collapsed rows")
	func ed235() async throws {
		let editor = try await EditorHarness.open("""
			- (+) Alpha
			  - A1
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 0)
		#expect(editor.visibleTitles == ["Alpha", "Bravo"])

		try await editor.press("n", .control)
		#expect(editor.cursorDescription == "\"Bravo\" @ 0")

		try await editor.press("p", .control)
		#expect(editor.cursorDescription == "\"Alpha\" @ 0")
		await editor.close()
	}

	@Test("ED-236 Esc while editing a row selects that row; Esc again returns the cursor to its text")
	func ed236() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)

		try await editor.press(UIKeyCommand.inputEscape)
		#expect(editor.selectedTitles == ["Alpha"])

		try await editor.press(UIKeyCommand.inputEscape)
		#expect(editor.cursorDescription == "\"Alpha\" @ 5")
		await editor.close()
	}

	@Test("ED-237 Tab and Shift-Tab are only offered while editing a row's topic, not its note or the title")
	func ed237() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  > a note
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 2)
		#expect(editor.offersKey("\t"))
		#expect(editor.offersKey("\t", .shift))

		try await editor.pressMenu("-", .control)
		#expect(editor.cursorDescription == "\"Alpha\" @ 6 (note)")
		#expect(editor.offersKey("\t") == false)
		#expect(editor.offersKey("\t", .shift) == false)

		try await editor.tapTitle()
		#expect(editor.offersKey("\t") == false)
		#expect(editor.offersKey("\t", .shift) == false)
		await editor.close()
	}

	@Test("ED-238 Focus In (Opt-Cmd-→) shows only the current row and its descendants; Focus Out (Opt-Cmd-←) shows the whole outline again")
	func ed238() async throws {
		let original = """
			- Alpha
			  - A1
			  - A2
			- Bravo
			"""
		let editor = try await EditorHarness.open(original)
		try await editor.placeCursor(in: "Alpha", at: 0)

		try await editor.pressMenu(UIKeyCommand.inputRightArrow, [.alternate, .command])
		#expect(editor.visibleTitles == ["Alpha", "A1", "A2"])

		try await editor.pressMenu(UIKeyCommand.inputLeftArrow, [.alternate, .command])
		#expect(editor.visibleTitles == ["Alpha", "A1", "A2", "Bravo"])
		expectOutline(editor.outline, original)
		await editor.close()
	}

	@Test("ED-239 Focus Out is unavailable when not focused")
	func ed239() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 0)

		#expect(editor.editor.canPerformAction(.focusOut, withSender: nil) == false)
		await editor.close()
	}
}

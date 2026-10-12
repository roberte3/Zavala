//
//  TitleTagsEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level behaviors of the title and the tags field above the rows (L2): editing the title, and moving
//  the cursor between the title, the tags field, and the rows with Return and the arrow keys.
//  Up from the first row into the tags field is ED-233. Adding and removing tags is P2.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Title and tags field in the editor", .serialized)
struct TitleTagsEditorBehaviors {

	@Test("ED-290 Typing in the title changes the outline's title (saved once typing pauses); Undo and Redo change it back and forth")
	func ed290() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			""")
		#expect(editor.outline.title == "Behavior Fixture")
		try await editor.tapTitle()

		try await editor.type(" Two")
		#expect(editor.titleText == "Behavior Fixture Two")
		try await editor.waitUntil("the outline's title is saved") {
			editor.outline.title == "Behavior Fixture Two"
		}

		// Title typing is undone on the title's own undo manager, as Cmd-Z in the title is.
		let undoManager = try #require(editor.focusedUndoManager)
		undoManager.undo()
		#expect(editor.titleText == "Behavior Fixture")
		try await editor.waitUntil("the undone title is saved") {
			editor.outline.title == "Behavior Fixture"
		}
		undoManager.redo()
		#expect(editor.titleText == "Behavior Fixture Two")
		try await editor.waitUntil("the redone title is saved") {
			editor.outline.title == "Behavior Fixture Two"
		}
		expectOutline(editor.outline, """
			- Alpha
			""")
		await editor.close()
	}

	@Test("ED-291 Return in the title moves the cursor to the tags field, without adding a line break to the title")
	func ed291() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			""")
		try await editor.tapTitle()

		try await editor.type("\n")
		try await editor.waitUntil("the tags field has keyboard focus") {
			editor.isTagFieldFocused
		}
		#expect(editor.titleText == "Behavior Fixture")
		#expect(editor.outline.title == "Behavior Fixture")
		await editor.close()
	}

	@Test("ED-292 Return in the empty tags field adds an empty row at the top of the outline and puts the cursor in it; Undo removes the row")
	func ed292() async throws {
		let before = """
			- Alpha
			- Bravo
			"""
		let editor = try await EditorHarness.open(before)
		try await editor.tapTagField()

		try await editor.type("\n")
		try await editor.waitUntil("the cursor is in a row") {
			editor.cursor != nil
		}
		#expect(editor.cursorDescription == "\"\" @ 0")
		#expect(editor.visibleTitles == ["", "Alpha", "Bravo"])
		expectUndoRedo(editor, before: before, after: """
			-
			- Alpha
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-293 Up arrow in the tags field moves the cursor to the end of the title")
	func ed293() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			""")
		try await editor.tapTagField()

		try await editor.pressKey(.keyboardUpArrow)
		try await editor.waitUntil("the title has keyboard focus") {
			editor.isTitleFocused
		}
		#expect(editor.titleSelection == NSRange(location: "Behavior Fixture".count, length: 0))
		await editor.close()
	}

	@Test("ED-294 Down arrow in the title moves the cursor to the tags field")
	func ed294() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			""")
		try await editor.tapTitle()

		try await editor.pressKey(.keyboardDownArrow)
		try await editor.waitUntil("the tags field has keyboard focus") {
			editor.isTagFieldFocused
		}
		await editor.close()
	}

	@Test("ED-295 Down arrow in the tags field moves the cursor to the end of the first row; in an empty outline it does nothing")
	func ed295() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await editor.tapTagField()

		try await editor.pressKey(.keyboardDownArrow)
		try await editor.waitUntil("the cursor is in a row") {
			editor.cursor != nil
		}
		#expect(editor.cursorDescription == "\"Alpha\" @ 5")
		await editor.close()

		let empty = try await EditorHarness.open("")
		try await empty.tapTagField()

		try await empty.pressKey(.keyboardDownArrow)
		#expect(empty.isTagFieldFocused)
		#expect(empty.cursor == nil)
		expectOutline(empty.outline, "")
		await empty.close()
	}

	@Test("ED-296 While focused in on a row, Return in the empty tags field moves the cursor to the end of the first row shown instead of adding a row")
	func ed296() async throws {
		let original = """
			- Alpha
			- Bravo
			  - B1
			  - B2
			"""
		let editor = try await EditorHarness.open(original)
		try await editor.placeCursor(in: "Bravo", at: 0)
		try await editor.pressMenu(UIKeyCommand.inputRightArrow, [.alternate, .command])
		#expect(editor.visibleTitles == ["Bravo", "B1", "B2"])
		try await editor.tapTagField()

		try await editor.type("\n")
		try await editor.waitUntil("the cursor is in a row") {
			editor.cursor != nil
		}
		#expect(editor.cursorDescription == "\"Bravo\" @ 5")
		#expect(editor.visibleTitles == ["Bravo", "B1", "B2"])
		expectOutline(editor.outline, original)
		await editor.close()
	}
}

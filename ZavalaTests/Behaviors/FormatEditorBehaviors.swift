//
//  FormatEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level text formatting behaviors (L2): Cmd-B, Cmd-I, Ctrl-Opt-Cmd-C, and Ctrl-Opt-Cmd-H on the
//  selected text, or on the text typed next. Formatting is checked as Markdown.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Formatting text in the editor", .serialized)
struct FormatEditorBehaviors {

	@Test("ED-270 Bold (Cmd-B) toggles bold on the selected text in a topic or note")
	func ed270() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.selectText(in: "Bravo", NSRange(location: 0, length: 5))

		try await editor.pressMenu("b", .command)
		try await expectFormatUndoRedo(editor, "Bravo", before: "Bravo", after: "**Bravo**")

		try await editor.pressMenu("b", .command)
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "Bravo", "Bravo")
		await editor.close()
	}

	@Test("ED-271 Italic (Cmd-I) toggles italic on the selected text")
	func ed271() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.selectText(in: "Bravo", NSRange(location: 1, length: 3))

		try await editor.pressMenu("i", .command)
		try await expectFormatUndoRedo(editor, "Bravo", before: "Bravo", after: "B_rav_o")

		try await editor.pressMenu("i", .command)
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "Bravo", "Bravo")
		await editor.close()
	}

	@Test("ED-272 Code (Ctrl-Opt-Cmd-C) toggles inline code style on the selected text")
	func ed272() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.selectText(in: "Bravo", NSRange(location: 0, length: 5))

		try await editor.pressMenu("c", [.command, .alternate, .control])
		try await expectFormatUndoRedo(editor, "Bravo", before: "Bravo", after: "`Bravo`")

		try await editor.pressMenu("c", [.command, .alternate, .control])
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "Bravo", "Bravo")
		await editor.close()
	}

	@Test("ED-273 Highlight (Ctrl-Opt-Cmd-H) toggles highlighting on the selected text")
	func ed273() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.selectText(in: "Bravo", NSRange(location: 0, length: 5))

		try await editor.pressMenu("h", [.command, .alternate, .control])
		try await expectFormatUndoRedo(editor, "Bravo", before: "Bravo", after: "==Bravo==")

		try await editor.pressMenu("h", [.command, .alternate, .control])
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "Bravo", "Bravo")
		await editor.close()
	}

	@Test("ED-274 With no text selected, a formatting command applies to the text typed next")
	func ed274() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Bravo", at: 5)

		try await editor.pressMenu("b", .command)
		try await editor.type("Xy")
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "BravoXy", "Bravo**Xy**")

		try await editor.pressMenu("b", .command)
		try await editor.type("z")
		try await editor.commitTyping()
		try expectTopicMarkdown(editor, "BravoXyz", "Bravo**Xy**z")
		await editor.close()
	}

	@Test("ED-276 Formatting changes are undoable")
	func ed276() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.selectText(in: "Bravo", NSRange(location: 0, length: 5))
		try await editor.pressMenu("b", .command)
		try await editor.commitTyping()

		// Removing the bold is undone and redone like any other change.
		try await editor.selectText(in: "Bravo", NSRange(location: 0, length: 5))
		try await editor.pressMenu("b", .command)
		try await expectFormatUndoRedo(editor, "Bravo", before: "**Bravo**", after: "Bravo")
		await editor.close()
	}
}

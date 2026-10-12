//
//  UndoSequenceEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level undo across typing and a structural edit (L2): typing and the row it
//  creates are separate undo steps. Model-level sequences are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Undo across typing and structure", .serialized)
struct UndoSequenceEditorBehaviors {

	@Test("ED-252 Typing in a row and then a structural edit undo separately: the first undo reverts the structure, the next reverts the typing")
	func ed252() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")
		try await editor.placeCursor(in: "Alpha", at: 5)
		try await editor.type("!")
		try await editor.type("\n")

		expectOutline(editor.outline, """
			- Alpha!
			-
			- Bravo
			""")

		editor.editor.undoManager?.undo()
		expectOutline(editor.outline, """
			- Alpha!
			- Bravo
			""")

		// Typed without saving first, as real keys are: the typing gets no undo step of its own.
		editor.editor.undoManager?.undo()
		withKnownIssue("ZB-012 The typing before Return is never undone") {
			expectOutline(editor.outline, """
				- Alpha
				- Bravo
				""")
		}
		await editor.close()
	}
}

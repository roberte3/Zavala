//
//  MoveRowEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level move up/down behaviors (L2): the menu shortcuts and where the cursor ends up.
//  Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Moving rows in the editor", .serialized)
struct MoveRowEditorBehaviors {

	@Test("ED-095 After Move Up/Down the cursor stays at the same position in the moved row")
	func ed095() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			- Charlie
			""")
		try await editor.placeCursor(in: "Bravo", at: 3)

		try await editor.pressMenu(UIKeyCommand.inputUpArrow, [.control, .command])
		#expect(editor.cursorDescription == "\"Bravo\" @ 3")
		expectOutline(editor.outline, """
			- Bravo
			- Alpha
			- Charlie
			""")

		try await editor.pressMenu(UIKeyCommand.inputDownArrow, [.control, .command])
		try await editor.pressMenu(UIKeyCommand.inputDownArrow, [.control, .command])
		#expect(editor.cursorDescription == "\"Bravo\" @ 3")
		expectOutline(editor.outline, """
			- Alpha
			- Charlie
			- Bravo
			""")
		await editor.close()
	}
}

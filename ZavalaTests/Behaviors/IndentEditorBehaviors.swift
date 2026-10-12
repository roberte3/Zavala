//
//  IndentEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level indent/outdent behaviors (L2). Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Indent / Outdent in the editor", .serialized)
struct IndentEditorBehaviors {

	@Test("ED-012 After Tab, the cursor stays at the same character position in the moved row")
	func ed012() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			- Bravo
			""")

		try await editor.placeCursor(in: "Bravo", at: 3)
		#expect(editor.offersKey("\t"), "Tab should be available while editing a topic")

		try await editor.press("\t")

		expectOutline(editor.outline, """
			- Alpha
			  - Bravo
			""")
		#expect(editor.cursorDescription == "\"Bravo\" @ 3")

		await editor.close()
	}
}

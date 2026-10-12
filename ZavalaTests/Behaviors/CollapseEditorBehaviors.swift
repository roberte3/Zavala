//
//  CollapseEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level collapse and expand behaviors (L2): Collapse Parent Row, the disclosure triangle,
//  and where the cursor goes when its row is hidden. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Collapse and expand in the editor", .serialized)
struct CollapseEditorBehaviors {

	@Test("ED-114 Collapse Parent Row (Ctrl-Opt-Cmd-0) collapses the parent of the current row")
	func ed114() async throws {
		let editor = try await EditorHarness.open("""
			- Alpha
			  - A1
			  - A2
			- Bravo
			""")
		try await editor.placeCursor(in: "A2", at: 1)

		try await editor.pressMenu("0", [.control, .alternate, .command])

		expectUndoRedo(editor, before: """
			- Alpha
			  - A1
			  - A2
			- Bravo
			""", after: """
			- (+) Alpha
			  - A1
			  - A2
			- Bravo
			""")
		await editor.close()
	}

	@Test("ED-115 Clicking a row's disclosure triangle toggles it; Option-click applies to all its descendants too")
	func ed115() async throws {
		let original = """
			- Alpha
			  - A1
			    - A1a
			- Bravo
			"""
		let click = try await EditorHarness.open(original)
		let alpha = try click.outline.row(titled: "Alpha")
		try await click.clickDisclosure(of: "Alpha")
		expectOutline(click.outline, """
			- (+) Alpha
			  - A1
			    - A1a
			- Bravo
			""")
		try await click.clickDisclosure(of: "Alpha")
		expectOutline(click.outline, original)
		#expect(alpha.isExpanded)
		await click.close()

		let optionClick = try await EditorHarness.open(original)
		try await optionClick.clickDisclosure(of: "Alpha", option: true)
		expectOutline(optionClick.outline, """
			- (+) Alpha
			  - (+) A1
			    - A1a
			- Bravo
			""")
		try await optionClick.clickDisclosure(of: "Alpha", option: true)
		expectOutline(optionClick.outline, original)
		await optionClick.close()
	}

	@Test("ED-117 Collapsing a row while the cursor is in one of its descendants moves the cursor to the end of the collapsed row")
	func ed117() async throws {
		let triangle = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await triangle.placeCursor(in: "A1", at: 1)
		try await triangle.clickDisclosure(of: "Alpha")
		#expect(triangle.cursorDescription == "\"Alpha\" @ 5")
		await triangle.close()

		let parent = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await parent.placeCursor(in: "A1", at: 1)
		try await parent.pressMenu("0", [.control, .alternate, .command])
		#expect(parent.cursorDescription == "\"Alpha\" @ 5")
		await parent.close()

		let all = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await all.placeCursor(in: "A1", at: 1)
		try await all.pressMenu("0", [.control, .command])
		withKnownIssue("ZB-008 Collapse All drops the cursor when it hides the cursor's row") {
			#expect(all.cursorDescription == "\"Alpha\" @ 5")
		}
		await all.close()

		let optionClick = try await EditorHarness.open("""
			- Alpha
			  - A1
			- Bravo
			""")
		try await optionClick.placeCursor(in: "A1", at: 1)
		try await optionClick.clickDisclosure(of: "Alpha", option: true)
		withKnownIssue("ZB-008 Collapse All drops the cursor when it hides the cursor's row") {
			#expect(optionClick.cursorDescription == "\"Alpha\" @ 5")
		}
		await optionClick.close()
	}
}

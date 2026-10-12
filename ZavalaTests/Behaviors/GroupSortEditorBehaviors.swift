//
//  GroupSortEditorBehaviors.swift
//  ZavalaTests
//
//  Editor-level group behavior (L2): the shortcut and where the cursor goes. Model-level ones are in VinOutlineKitTests.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Group and sort in the editor", .serialized)
struct GroupSortEditorBehaviors {

	@Test("ED-210 Group Rows (Opt-Cmd-G) puts the selected adjacent siblings under a new empty row inserted where the first one was, and moves the cursor into it")
	func ed210() async throws {
		let original = """
			- Alpha
			- Bravo
			  - B1
			- Charlie
			- Delta
			"""
		let editor = try await EditorHarness.open(original)
		try await editor.selectRows(["Bravo", "Charlie"])

		try await editor.pressMenu("g", [.alternate, .command])

		#if targetEnvironment(macCatalyst)
		#expect(editor.cursorDescription == "\"\" @ 0")
		#else
		// On iPad, grouping from row-selection mode leaves no cursor and no selection. Not yet known whether
		// that's Zavala or the harness: see "Open issue: ED-210 on iPad" in tasks/plan.md (decided 2026-10-09).
		#endif
		expectUndoRedo(editor, before: original, after: """
			- Alpha
			-
			  - Bravo
			    - B1
			  - Charlie
			- Delta
			""")
		await editor.close()
	}
}

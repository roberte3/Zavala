//
//  CollapseBehaviors.swift
//  VinOutlineKitTests
//
//  ED-110 … ED-117: Collapse and expand (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
@testable import VinOutlineKit

@Suite("Collapse and expand")
final class CollapseBehaviors: VOKTestCase {

	@Test("ED-110 Collapse (Cmd-0) hides a row's descendants; Expand (Cmd-9) shows them again with their own collapse state intact")
	func ed110() async throws {
		let original = """
			- A
			  - A1
			    - A1a
			  - (+) A2
			    - A2a
			- B
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		let a = try outline.row(titled: "A")
		let collapsed = """
			- (+) A
			  - A1
			    - A1a
			  - (+) A2
			    - A2a
			- B
			"""

		CollapseCommand(actionName: "Collapse", undoManager: undoManager, delegate: self, outline: outline, rows: [a]).execute()
		expectEdit(outline, before: original, after: collapsed)
		#expect(visibleRows(outline) == ["A", "B"])

		undoManager.removeAllActions()
		ExpandCommand(actionName: "Expand", undoManager: undoManager, delegate: self, outline: outline, rows: [a]).execute()
		expectEdit(outline, before: collapsed, after: original)
		#expect(visibleRows(outline) == ["A", "  A1", "    A1a", "  A2", "B"])
	}

	@Test("ED-111 Collapse and Expand are unavailable for rows without children")
	func ed111() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- A
			  - A1
			- (+) B
			  - B1
			- C
			""")
		defer { deleteAccountManager(accountManager) }
		let a = try outline.row(titled: "A")
		let b = try outline.row(titled: "B")
		let c = try outline.row(titled: "C")

		// What the Collapse and Expand menu items check.
		#expect(!c.isCollapsable)
		#expect(!c.isExpandable)
		#expect(!(try outline.row(titled: "A1")).isCollapsable)
		// A row with children offers whichever one applies.
		#expect(a.isCollapsable && !a.isExpandable)
		#expect(b.isExpandable && !b.isCollapsable)
	}

	@Test("ED-112 Collapse All in Row (Opt-Cmd-0) collapses the row and every descendant with children; Expand All in Row (Opt-Cmd-9) expands them all")
	func ed112() async throws {
		let original = """
			- A
			  - A1
			    - A1a
			      - A1a1
			  - A2
			- B
			  - B1
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		let a = try outline.row(titled: "A")
		let collapsed = """
			- (+) A
			  - (+) A1
			    - (+) A1a
			      - A1a1
			  - A2
			- B
			  - B1
			"""

		#expect(!outline.isCollapseAllUnavailable(containers: [a]))
		CollapseAllCommand(actionName: "Collapse All", undoManager: undoManager, delegate: self, outline: outline, containers: [a]).execute()
		expectEdit(outline, before: original, after: collapsed)
		#expect(outline.isCollapseAllUnavailable(containers: [a]))

		undoManager.removeAllActions()
		ExpandAllCommand(actionName: "Expand All", undoManager: undoManager, delegate: self, outline: outline, containers: [a]).execute()
		expectEdit(outline, before: collapsed, after: original)
		#expect(outline.isExpandAllUnavailable(containers: [a]))
	}

	@Test("ED-113 Collapse All in Outline (Ctrl-Cmd-0) and Expand All in Outline (Ctrl-Cmd-9) apply to every row with children")
	func ed113() async throws {
		let original = """
			- A
			  - A1
			    - A1a
			- B
			- C
			  - C1
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }
		let collapsed = """
			- (+) A
			  - (+) A1
			    - A1a
			- B
			- (+) C
			  - C1
			"""

		#expect(!outline.isCollapseAllInOutlineUnavailable)
		CollapseAllCommand(actionName: "Collapse All", undoManager: undoManager, delegate: self, outline: outline, containers: [outline]).execute()
		expectEdit(outline, before: original, after: collapsed)
		#expect(visibleRows(outline) == ["A", "B", "C"])
		#expect(outline.isCollapseAllInOutlineUnavailable)

		undoManager.removeAllActions()
		ExpandAllCommand(actionName: "Expand All", undoManager: undoManager, delegate: self, outline: outline, containers: [outline]).execute()
		expectEdit(outline, before: collapsed, after: original)
		#expect(outline.isExpandAllInOutlineUnavailable)
	}

	@Test("ED-116 Collapse and expand are undoable")
	func ed116() async throws {
		// Undo reverses only what the command changed: rows that were already collapsed stay collapsed.
		let original = """
			- A
			  - A1
			- (+) B
			  - B1
			"""
		let (outline, accountManager) = try await makeOutline(original)
		defer { deleteAccountManager(accountManager) }

		CollapseAllCommand(actionName: "Collapse All", undoManager: undoManager, delegate: self, outline: outline, containers: [outline]).execute()
		expectEdit(outline, before: original, after: """
			- (+) A
			  - A1
			- (+) B
			  - B1
			""")

		undoManager.removeAllActions()
		ExpandAllCommand(actionName: "Expand All", undoManager: undoManager, delegate: self, outline: outline, containers: [outline]).execute()
		expectEdit(outline, before: """
			- (+) A
			  - A1
			- (+) B
			  - B1
			""", after: """
			- A
			  - A1
			- B
			  - B1
			""")
	}

	// MARK: Helpers

	/// The rows shown in the editor, indented by level.
	private func visibleRows(_ outline: Outline) -> [String] {
		(outline.shadowTable ?? []).map { String(repeating: "  ", count: $0.trueLevel) + ($0.topic?.string ?? "") }
	}
}

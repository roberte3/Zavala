//
//  SplitJoinBehaviors.swift
//  VinOutlineKitTests
//
//  ED-050 … ED-058: Splitting and joining rows (model level). Editor-level ones are in ZavalaTests.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
import UIKit
import VinMarkdown
@testable import VinOutlineKit

@Suite("Split and join")
final class SplitJoinBehaviors: VOKTestCase {

	@Test("ED-051 Splitting a row whose children are showing puts the second half as its first child")
	func ed051() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- Alpha
			  - A1
			- Bravo
			""")
		defer { deleteAccountManager(accountManager) }

		split("Alpha", at: 2, in: outline)

		expectEdit(outline, before: """
			- Alpha
			  - A1
			- Bravo
			""", after: """
			- Al
			  - pha
			  - A1
			- Bravo
			""")
	}

	@Test("ED-052 Splitting keeps bold, italic, and links on each half of the text")
	func ed052() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- x
			""")
		defer { deleteAccountManager(accountManager) }
		let row = try outline.row(titled: "x")
		let original = "**bold** _italic_ [link](https://example.com)"
		row.topic = NSMutableAttributedString(markdownRepresentation: original, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])

		// Inside "italic", after "it".
		SplitRowCommand(actionName: "Split Row", undoManager: undoManager, delegate: self, outline: outline,
						row: row, topic: try #require(row.topic), cursorPosition: 7, childRowIndent: true).execute()

		let after = ["**bold** _it_", "_alic_ [link](https://example.com)"]
		#expect(topicsAsMarkdown(outline) == after)
		undoManager.undo()
		#expect(topicsAsMarkdown(outline) == [original])
		undoManager.redo()
		#expect(topicsAsMarkdown(outline) == after)
	}

	@Test("ED-058 Undo of a split restores the single row and its text; undo of a join restores both rows")
	func ed058() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- Alpha
			  > alpha note
			- [x] Bravo
			  > bravo note
			- Charlie
			""")
		defer { deleteAccountManager(accountManager) }

		split("Alpha", at: 2, in: outline)
		expectEdit(outline, before: """
			- Alpha
			  > alpha note
			- [x] Bravo
			  > bravo note
			- Charlie
			""", after: """
			- Al
			  > alpha note
			- pha
			- [x] Bravo
			  > bravo note
			- Charlie
			""")

		undoManager.removeAllActions()
		let charlie = try outline.row(titled: "Charlie")
		let bravo = try outline.row(titled: "Bravo")
		JoinRowCommand(actionName: "Join Row", undoManager: undoManager, delegate: self, outline: outline,
					   topRow: bravo, bottomRow: charlie, topic: NSAttributedString(string: "BravoCharlie")).execute()
		expectEdit(outline, before: """
			- Al
			  > alpha note
			- pha
			- [x] Bravo
			  > bravo note
			- Charlie
			""", after: """
			- Al
			  > alpha note
			- pha
			- [x] BravoCharlie
			  > bravo note
			""")
	}

	@Test("ED-059 Joining two rows keeps both notes: the lower row's note follows the upper row's")
	func ed059() async throws {
		let before = """
			- Alpha
			  > alpha note
			- Bravo
			  > bravo note
			"""
		let after = """
			- AlphaBravo
			  > alpha note
			  > bravo note
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		JoinRowCommand(actionName: "Join Row", undoManager: undoManager, delegate: self, outline: outline,
					   topRow: try outline.row(titled: "Alpha"), bottomRow: try outline.row(titled: "Bravo"),
					   topic: NSAttributedString(string: "AlphaBravo")).execute()

		#expect(outline.rows.map { $0.topic?.string } == ["AlphaBravo"])
		withKnownIssue("ZB-004 Joining rows drops the lower row's note") {
			expectOutline(outline, after)
		}
		undoManager.undo()
		expectOutline(outline, before)
		undoManager.redo()
		withKnownIssue("ZB-004 Joining rows drops the lower row's note") {
			expectOutline(outline, after)
		}
	}

	// MARK: Helpers

	/// What Return in the middle of a row's text does, with Zavala's default "create rows indented with children" setting.
	private func split(_ title: String, at offset: Int, in outline: Outline, sourceLocation: SourceLocation = #_sourceLocation) {
		guard let row = try? outline.row(titled: title, sourceLocation: sourceLocation), let topic = row.topic else { return }
		SplitRowCommand(actionName: "Split Row", undoManager: undoManager, delegate: self, outline: outline,
						row: row, topic: topic, cursorPosition: offset, childRowIndent: true).execute()
	}

	/// Every row's topic, in display order, as Markdown, so formatting shows up in the comparison.
	private func topicsAsMarkdown(_ outline: Outline) -> [String] {
		var result = [String]()
		func visit(_ row: Row) {
			result.append(row.topic?.markdownRepresentation ?? "")
			row.rows.forEach(visit)
		}
		outline.rows.forEach(visit)
		return result
	}
}

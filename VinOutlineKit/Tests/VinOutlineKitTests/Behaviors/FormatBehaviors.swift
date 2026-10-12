//
//  FormatBehaviors.swift
//  VinOutlineKitTests
//
//  ED-275: Formatting stays with its text when rows are moved, copied, split, or joined (model level).
//  Formatting is checked as Markdown, since the outline DSL doesn't carry it.
//  Sentences live in planning/behaviors/BEHAVIORS.md.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit

@Suite("Keeping formatting with its text")
final class FormatBehaviors: VOKTestCase {

	@Test("ED-275 Formatting stays with its text when the row is moved, copied, split, or joined")
	func ed275() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- Alpha
			- Bravo
			- Charlie
			""")
		defer { deleteAccountManager(accountManager) }
		let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body)]

		// Move: "Alpha" (bold) moves below "Bravo" and keeps its bold.
		let alpha = try outline.row(titled: "Alpha")
		alpha.topic = NSMutableAttributedString(markdownRepresentation: "**Alpha**", attributes: attributes)
		undoManager.removeAllActions()
		MoveRowDownCommand(actionName: "Move Down", undoManager: undoManager, delegate: self, outline: outline,
						   rows: [alpha], rowStrings: nil).execute()
		#expect(outline.rows.map { $0.topic?.markdownRepresentation ?? "" } == ["Bravo", "**Alpha**", "Charlie"])

		// Duplicate: the copy of "Charlie" (italic) keeps its italic.
		let charlie = try outline.row(titled: "Charlie")
		charlie.topic = NSMutableAttributedString(markdownRepresentation: "_Charlie_", attributes: attributes)
		DuplicateRowCommand(actionName: "Duplicate Rows", undoManager: undoManager, delegate: self, outline: outline,
							rows: [charlie]).execute()
		#expect(outline.rows.map { $0.topic?.markdownRepresentation ?? "" } == ["Bravo", "**Alpha**", "_Charlie_", "_Charlie_"])

		// Split: "Charlie" split after "Char" keeps its italic on both halves.
		let copy = outline.rows[3]
		SplitRowCommand(actionName: "Split Row", undoManager: undoManager, delegate: self, outline: outline,
						row: copy, topic: try #require(copy.topic), cursorPosition: 4, childRowIndent: true).execute()
		#expect(outline.rows.map { $0.topic?.markdownRepresentation ?? "" } == ["Bravo", "**Alpha**", "_Charlie_", "_Char_", "_lie_"])

		// Join: "**Alpha**" and "_Bravo_" join into one row that keeps both formats.
		let bravo = try outline.row(titled: "Bravo")
		bravo.topic = NSMutableAttributedString(markdownRepresentation: "_Bravo_", attributes: attributes)
		let alphaRow = try outline.row(titled: "Alpha")
		JoinRowCommand(actionName: "Join Row", undoManager: undoManager, delegate: self, outline: outline,
					   topRow: bravo, bottomRow: alphaRow,
					   topic: NSMutableAttributedString(markdownRepresentation: "_Bravo_**Alpha**", attributes: attributes)).execute()
		#expect(outline.rows.first?.topic?.markdownRepresentation == "_Bravo_**Alpha**")
	}
}

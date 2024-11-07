//
//  CustomOTPTextField.swift
//  HudHud
//
//  Created by Patrick Kladek on 07.11.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

import Foundation
import UIKit

final class CustomOTPTextField: UITextField {

    // MARK: Overridden Properties

    override var selectedTextRange: UITextRange? {
        get {
            if self.isLastField, self.allFieldsFilled {
                return super.selectedTextRange
            }
            return nil
        }
        set {
            if self.isLastField, self.allFieldsFilled {
                super.selectedTextRange = newValue
            }
        }
    }

    // MARK: Properties

    var onBackspace: (() -> Void)?
    var onPasteOrAutofill: ((String) -> Void)?
    var isLastField: Bool = false
    var allFieldsFilled: Bool = false

    // MARK: Overridden Functions

    override func deleteBackward() {
        if let onBackspace, text?.isEmpty ?? true {
            onBackspace()
        }
        super.deleteBackward()
    }

    override func canPerformAction(_ action: Selector, withSender _: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return true
        }
        if self.isLastField, self.allFieldsFilled {
            return action == #selector(UIResponderStandardEditActions.copy(_:))
        }
        return false
    }

    override func paste(_: Any?) {
        if let pasteboardString = UIPasteboard.general.string {
            self.onPasteOrAutofill?(pasteboardString)
        }
    }

    override func insertText(_ text: String) {
        if text.count > 1 {
            self.onPasteOrAutofill?(text)
        } else {
            super.insertText(text)
        }
    }

    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.closestPosition(to: point)
        }
        return endOfDocument
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        if self.isLastField, self.allFieldsFilled {
            return super.caretRect(for: position)
        }
        return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        if self.isLastField, self.allFieldsFilled {
            return super.selectionRects(for: range)
        }
        return []
    }

    override func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.position(from: position, offset: offset)
        }
        return endOfDocument
    }

    override func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        if self.isLastField, self.allFieldsFilled {
            return super.position(from: position, in: direction, offset: offset)
        }
        return endOfDocument
    }

    override func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        if self.isLastField, self.allFieldsFilled {
            return super.textRange(from: fromPosition, to: toPosition)
        }
        let endPosition = self.position(from: endOfDocument, offset: 0) ?? endOfDocument
        return super.textRange(from: endPosition, to: endPosition)
    }
}

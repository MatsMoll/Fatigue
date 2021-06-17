//
//  NumberField.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import SwiftUI

extension NumberFormatter {
    static let defaultFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

#if os(iOS)
struct NumberField<V>: UIViewRepresentable where V: Numeric & LosslessStringConvertible {
    
    @Binding var value: V?
    
    var keyboardType: UIKeyboardType = .numberPad
    
    var formatter: NumberFormatter = .defaultFormatter

    typealias UIViewType = UITextField

    func makeUIView(context: UIViewRepresentableContext<NumberField>) -> UITextField {
        let editField = UITextField()
        editField.delegate = context.coordinator
        editField.keyboardType = keyboardType
        return editField
    }

    func updateUIView(_ editField: UITextField, context: UIViewRepresentableContext<NumberField>) {
        if let value = value {
            if let doubleValue = Double(String(value)) {
                editField.text = formatter.string(from: .init(value: doubleValue))
            } else {
                editField.text = String(value)
            }
        } else {
            editField.text = ""
        }
    }

    func makeCoordinator() -> NumberField.Coordinator {
        Coordinator(value: $value)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var value: Binding<V?>

        init(value: Binding<V?>) {
            self.value = value
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {

            let text = textField.text as NSString?
            let newValue = text?.replacingCharacters(in: range, with: string)

            if
                let newValue = newValue,
                let number = V(newValue)
            {
                self.value.wrappedValue = number
            } else {
                if nil == newValue || newValue!.isEmpty {
                    self.value.wrappedValue = nil
                }
            }
            return true
        }

        
        func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {

            if
                let finalText = textField.text,
                let number = V(finalText.replacingOccurrences(of: ",", with: "."))
            {
                self.value.wrappedValue = number
            }
        }
    }
}

extension NumberField {
    
    init(_ value: Binding<V>, keyboardType: UIKeyboardType = .numberPad, formatter: NumberFormatter = .defaultFormatter) {
        self.init(value: .init(get: {
            value.wrappedValue
        }, set: { newValue in
            if let newValue = newValue {
                value.wrappedValue = newValue
            }
        }), keyboardType: keyboardType, formatter: formatter)
    }
    
    init(_ value: Binding<Optional<V>>, keyboardType: UIKeyboardType = .numberPad, formatter: NumberFormatter = .defaultFormatter) {
        self.init(value: value, keyboardType: keyboardType, formatter: formatter)
    }
}

struct NumberField_Previews: PreviewProvider {
    static var previews: some View {
        NumberField(value: .init(get: { 10 }, set: { _ in }))
    }
}
#endif

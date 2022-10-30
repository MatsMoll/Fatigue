//
//  Array+toCsv.swift
//  Fatigue
//
//  Created by Mats Mollestad on 21/07/2021.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension Array {
    
    func toCsv(_ fields: [(String, KeyPath<Element, String?>)]) -> String {
        let columns = String(fields.map(\.0).reduce("", { $0 + $1 + "," }).dropLast()) + "\n"
        let keyPaths = fields.map(\.1)
        return self.reduce(into: columns) { (result, element) in
            var line = ""
            for path in keyPaths {
                if let value = element[keyPath: path] {
                    line += value + ","
                } else {
                    line += ","
                }
            }
            line.removeLast()
            result += line + "\n"
        }
    }
}

struct CSVFile: FileDocument {
    static var readableContentTypes = [UTType.plainText]

    var text = ""

    init<T>(elements: Array<T>, fields: [(String, KeyPath<T, String?>)]) {
        text = elements.toCsv(fields)
    }
    
    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

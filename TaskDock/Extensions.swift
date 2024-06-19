//
//  Extensions.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/20/23.
//

import SwiftUI

extension Dictionary {
    /// Helpful extension that lets us initialize a dictionary element if it doesn't exist with one subscript call like
    /// this:
    /// `let value = dict[key, orInit: Value()]`
    /// Because we use autoclosure, the Value will only be instantiated if it's needed
    subscript(key: Key, orInit or: @autoclosure () -> Value) -> Value {
        mutating get {
            return self[key] ?? {
                let value = or()
                self[key] = value
                return value
            }()
        }
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension View {
    func fadeOutSides(fadeLength:CGFloat=8) -> some View {
        return mask(
            HStack(spacing: 0) {
                
                // Left gradient
                LinearGradient(gradient: Gradient(
                    colors: [Color.black.opacity(0), Color.black]),
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: fadeLength)
                
                // Middle
                Rectangle().fill(Color.black)
                
                // Right gradient
                LinearGradient(gradient: Gradient(
                    colors: [Color.black, Color.black.opacity(0)]),
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: fadeLength)
            }
        )
    }
}

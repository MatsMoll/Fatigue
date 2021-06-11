//
//  AsyncView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import SwiftUI
import Combine

enum LoadingState<Value> {
    case idle
    case loading(progress: Double? = nil)
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load()
}

class PublishedObject<Wrapped: Publisher>: LoadableObject {
    @Published private(set) var state = LoadingState<Wrapped.Output>.idle

    private let publisher: Wrapped
    private var cancellable: AnyCancellable?

    init(publisher: Wrapped) {
        self.publisher = publisher
    }

    func load() {
        state = .loading()

        cancellable = publisher
            .map(LoadingState.loaded)
            .catch { error in
                Just(LoadingState.failed(error))
            }
            .sink { [weak self] state in
                self?.state = state
            }
    }
}

struct ErrorView: View {
    
    let error: Error
    let retryHandler: () -> Void
    
    var body: some View {
        VStack {
            Text("Ups! An error ocurred")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .foregroundColor(.secondary)
            
            Button("Retry", action: retryHandler)
                .padding()
        }
    }
}

struct AsyncContentView<Source: LoadableObject, Content: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    
    var loadingText: String = ""

    var body: some View {
        switch source.state {
        case .idle:
            Color.clear.onAppear(perform: source.load)
        case .loading(let progress):
            if let value = progress {
                ProgressView("\(loadingText) \(Int(value * 100))%", value: value)
            } else {
                ProgressView(loadingText)
            }
        case .failed(let error):
            ErrorView(error: error, retryHandler: source.load)
        case .loaded(let output):
            content(output)
        }
    }
}

extension AsyncContentView {
    init<P: Publisher>(
        source: P,
        @ViewBuilder content: @escaping (P.Output) -> Content
    ) where Source == PublishedObject<P> {
        self.init(
            source: PublishedObject(publisher: source),
            content: content
        )
    }
}

class StaticObject<T>: LoadableObject {
    
    @Published private(set)
    var state: LoadingState<T>

    private let onLoad: () -> Void

    init(state: LoadingState<T>, onLoad: @escaping () -> Void) {
        self.state = state
        self.onLoad = onLoad
    }

    func load() {
        onLoad()
    }
}

extension AsyncContentView {
    init<T>(
        value: LoadingState<T>,
        onLoad: @escaping () -> Void,
        @ViewBuilder content: @escaping (T) -> Content
    ) where Source == StaticObject<T> {
        self.init(
            source: StaticObject(state: value, onLoad: onLoad),
            content: content
        )
    }
}

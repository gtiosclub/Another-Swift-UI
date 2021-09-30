//
//  ContentView.swift
//  Another_UI_in_swift
//
//  Created by Maksim Tochilkin on 9/30/21.
//

import SwiftUI
import Combine

struct ContentView: View {
    @iOSClubState private var width: Double = 300.0
    @ObservedObject var updater: Updater
    @State private var opacity: Double = 0.5
    
    let size = CGSize(width: 800, height: 600)
    
    var sample: some View_ {
        Rectangle_()
            .frame(width: 30, height: 30)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Image(nsImage: NSImage(data: render(size: size, view: sample))!)
                    .opacity(1 - opacity)

                sample.swiftUI
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .opacity(opacity)

            }

            Slider(value: $opacity, in: 0...1)
        }
    }
}


class Updater: ObservableObject, DynamicProperty_ {
    func updateView() {
        self.objectWillChange.send()
    }
}

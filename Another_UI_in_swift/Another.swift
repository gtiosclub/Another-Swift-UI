//
//  Another.swift
//  Another_UI_in_swift
//
//  Created by Maksim Tochilkin on 9/30/21.
//

import Foundation
import SwiftUI
import Combine

typealias RenderingContext = CGContext
typealias ProposedSize = CGSize


protocol View_ {
    associatedtype Body: View_
    associatedtype SwiftUIBody: View
    var body: Body { get }

    //DEBUG
    var swiftUI: SwiftUIBody { get }
}


protocol BuiltinView {
    typealias Body = Never
    func render(context: RenderingContext, size: CGSize)
    func size(proposed: ProposedSize) -> CGSize
}

extension Never: View_ {
    typealias Body = Never
    var swiftUI: Never { fatalError("Should never be called") }
}

extension View_ where Body == Never {
    var body: Never { fatalError("This should never be called.") }
}

protocol Shape_: View_ {
    func path(in rect: CGRect) -> CGPath
}

extension Shape_ {
    var body: ShapeView<Self> {
        ShapeView(shape: self)
    }

    var swiftUI: AnyShape {
        AnyShape(self)
    }
}

struct AnyShape: Shape {
    let path: (CGRect) -> CGPath

    init<S: Shape_>(_ content: S) {
        self.path = content.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        Path(path(rect))
    }

}


struct ShapeView<S: Shape_>: View_, BuiltinView {
    let shape: S

    func render(context: RenderingContext, size: CGSize) {
        context.saveGState()
        context.addPath(self.shape.path(in: CGRect(origin: .zero, size: size)))
        context.fillPath()
        context.restoreGState()
    }

    func size(proposed: ProposedSize) -> CGSize {
        return proposed
    }

    var swiftUI: some View {
        AnyShape(shape)
    }
}

struct Rectangle_: Shape_ {

    func path(in rect: CGRect) -> CGPath {
        CGPath(rect: rect, transform: nil)
    }
}

extension View_ {
    func _render(context: RenderingContext, size: CGSize) {
        if let builtin = self as? BuiltinView {
            builtin.render(context: context, size: size)
        } else {
            self.body._render(context: context, size: size)
        }
    }

    func _size(proposed: ProposedSize) -> CGSize {
        if let builtin = self as? BuiltinView {
            return builtin.size(proposed: proposed)
        } else {
            return body._size(proposed: proposed)
        }
    }
}


struct FixedFrame<Content: View_>: View_, BuiltinView {
    let width: CGFloat?
    let height: CGFloat?
    let content: Content

    func size(proposed: ProposedSize) -> CGSize {
        let childSize = content._size(proposed: CGSize(width: width ?? proposed.width, height: height ?? proposed.height))
        return CGSize(width: width ?? childSize.width, height: height ?? childSize.height)
    }

    func render(context: RenderingContext, size: CGSize) {
        context.saveGState()
        let childSize = content._size(proposed: size)

//        let selfPoint = self.alignment.point(in: size)
//        let childPoint = self.alignment.point(in: childSize)
//
        context.translateBy(x: (size.width - childSize.width) / 2, y: (size.height - childSize.height) / 2)
        content._render(context: context, size: childSize)
        context.restoreGState()
    }

    var swiftUI: some View {
        content.swiftUI.frame(width: self.width, height: self.height)
    }
}

extension View_ {
    func frame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View_ {
        FixedFrame(width: width, height: height, content: self)
    }
}


@propertyWrapper
class iOSClubState<Value>: DynamicProperty, ViewGraphInjectable_ {
    var value: Value
    var stateWillChange = PassthroughSubject<Void, Never>()
    var viewGraph: DynamicProperty_?
    
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    func setViewGraph(_ graph: DynamicProperty_) {
        self.viewGraph = graph
    }
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            render()
        }
    }
    
    func render() {
        viewGraph?.updateView()
    }
}

protocol DynamicProperty_ {
    func updateView()
}

protocol ViewGraphInjectable_ {
    func setViewGraph(_ graph: DynamicProperty_)
}

//
//  CollapsableSection.swift
//  GlucoseDirectApp
//

import SwiftUI

// MARK: - CollapsableSection

struct CollapsableSection<Parent, Content, Teaser>: View where Parent: View, Content: View, Teaser: View {
    // MARK: Lifecycle
    
    init(teaser: Teaser, header: Parent, collapsed: Bool = false, collapsible: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.teaser = teaser
        self.header = header
        self._collapsed = State(initialValue: collapsed)
        self.collapsible = collapsible
        self.content = content
    }

    // MARK: Internal

    let header: Parent
    let content: () -> Content
    let teaser: Teaser

    var body: some View {
        Section(
            header: HStack {
                header
                Spacer()
                
                if collapsible {
                    Button(action: {
                        collapsed.toggle()
                    }, label: {
                        Image(systemName: collapsed ? "chevron.up" : "chevron.down")
                    }).buttonStyle(.plain)
                }
            }
        ) {
            Group {
                if collapsed {
                    teaser
                } else {
                    content()
                }
            }
        }
    }

    // MARK: Private

    @State private var collapsed: Bool
    private var collapsible: Bool
}

extension CollapsableSection where Teaser == EmptyView {
    init(header: Parent, collapsed: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.init(teaser: EmptyView(), header: header, collapsed: collapsed, content: content)
    }
}

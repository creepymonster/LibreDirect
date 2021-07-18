//
//  KeyValueEditorView.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import SwiftUI

typealias EditorCompletionHandler = (_ value: String) -> Void

struct KeyValueEditorView: View {
    let key: String
    let completionHandler: EditorCompletionHandler?
    
    @State var value: String

    init(key: String, value: String, completionHandler: EditorCompletionHandler? = nil) {
        self.key = key
        self.value = value
        self.completionHandler = completionHandler
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(key)
                .font(Font.body.weight(.semibold))
                .frame(maxWidth: 100, alignment: .leading)

            TextField("", text: $value)
                .onChange(of: value, perform: { value in
                    if let completionHandler = completionHandler {
                        completionHandler(value)
                    }
                })
                .font(Font.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct KeyValueEditorView_Previews: PreviewProvider {
    static var previews: some View {
        KeyValueEditorView(key: "Key", value: "Value")
    }
}

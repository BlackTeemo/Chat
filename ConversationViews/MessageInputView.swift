//
//  MessageInputView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct MessageInputView: View {
    
    @EnvironmentObject var store: Store
    let conversation : Conversation
    
    @State private var content = ""
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("输入消息…")
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $content)
                    .frame(minHeight: 56, maxHeight: 110)
                    .scrollContentBackground(.hidden)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.borderedProminent)
            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
        .background(.thinMaterial)
    }
    
    func sendMessage(){
        let value = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        store.sendMessage(to: conversation, content: value)
        content = ""
    }
}

//#Preview {
//    MessageInputView()
//}

//
//  LoginView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store : Store
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegister = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "message.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text("欢迎登录")
                    .font(.largeTitle.bold())
                
            }
            
            Form{
                Picker("模式", selection: $isRegister) {
                    Text("登录").tag(false)
                    Text("注册").tag(true)
                }
                .pickerStyle(.segmented)
                
                TextField("用户名", text: $username)
                
                SecureField("密码", text: $password)

                if isRegister {
                    SecureField("确认密码", text: $confirmPassword)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    handleSubmit()
                } label: {
                    Text(isRegister ? "注册" : "登录")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    func handleSubmit() {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedPassword.isEmpty else {
            statusMessage = "用户名和密码不能为空"
            return
        }
        
        if isRegister {
            guard password == confirmPassword else {
                statusMessage = "两次密码不一致"
                return
            }
            
            if store.register(username: trimmedName, password: trimmedPassword) {
                statusMessage = "注册成功，已登录"
            } else {
                statusMessage = "用户名已存在"
            }
        } else {
            if store.login(username: trimmedName, password: trimmedPassword) {
                statusMessage = "登录成功"
            } else {
                statusMessage = "用户名或密码错误"
            }
        }
    }
}



# Chat

> 最后更新：2026/5/30

> 2026/5/30 下午：登录页面、会话列表、聊天消息展示、消息发送。

> 2026/5/30 晚上新增：添加好友、创建群聊、邀请用户进群、群聊标识与成员管理。

一个基于 SwiftUI 的 iOS 聊天应用 Demo。

## 功能

- **登录页面** — 输入用户名和密码即可进入（当前为演示逻辑，未接入真实后端）
- **会话列表** — 侧边栏展示所有对话，支持显示群聊标识、最近消息预览，点击切换选中状态
- **工具栏入口** — 侧边栏顶部提供「加好友」（人像加号图标）和「创建群聊」（加号圆圈图标）按钮
- **添加好友** — 弹窗输入用户名/ID，添加后自动在会话列表创建新对话
- **创建群聊** — 弹窗填写群名称并选择成员，创建后在会话列表显示群聊标签
- **聊天界面** — 显示消息气泡列表，空状态引导提示，支持发送按钮和回车发送
- **群聊头部** — 显示头像、群聊/私聊标签、成员数，仅群聊显示「邀请」按钮
- **邀请进群** — 群聊头部点击邀请按钮，弹窗选择用户加入群聊

## 项目结构

```
Chat/
├── ChatApp.swift                 # App 入口，初始化全局 Store
├── ContentView.swift             # 根视图，根据登录状态切换页面
├── LoginView.swift               # 登录页面
├── MainView.swift                # 主页面，管理选中会话，空状态引导
├── SidebarView.swift             # 侧边栏会话列表 + 工具栏入口
├── ConversationView.swift        # 聊天对话页面，协调头部/消息/输入
├── ConversationViews/
│   ├── HeaderView.swift          # 对话头部（头像、标签、邀请按钮）
│   ├── ChatMessageView.swift     # 消息气泡列表（ScrollView 自定义样式）
│   ├── MessageInputView.swift    # 消息输入框（占位符、发送按钮）
│   ├── AddFriendView.swift       # 添加好友弹窗
│   ├── CreateGroupView.swift     # 创建群聊弹窗
│   └── InviteUserView.swift      # 邀请用户进群弹窗
└── Models/
    ├── Conversation.swift        # 对话数据模型（支持 isGroup / groupMembers）
    ├── User.swift                # 用户模型
    └── Store.swift               # 全局状态管理 + 业务方法
```

## 技术栈

- **SwiftUI** — 声明式 UI 框架
- **MVVM** 架构模式，通过 `ObservableObject` / `@Published` 管理状态
- **NavigationSplitView** 实现三栏式导航布局

## 运行

使用 Xcode 打开 `Chat.xcodeproj`，选择模拟器或真机后运行即可。

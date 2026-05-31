# Chat

> 最后更新：2026/6/1

> 2026/5/30 ：登录页面、会话列表、聊天消息展示、消息发送。

> 2026/5/30 新增：添加好友、创建群聊、邀请用户进群、群聊标识与成员管理。

> 2026/5/31 重构：统一 Core Data 存储、消息发送者识别、私聊标题修复、UI 弹窗布局调整。


> 2026/5/31 修复：如果我同时打开两个这个app，一个登陆user1一个登陆admin，现在user1给admin发信息，admin所在的app无法实时更新消息，必须再次登陆才能看到，群聊也是这样

> 2026/5/31 修复：创建群聊和邀请进群改为仅显示好友列表，而非全部用户；添加好友后自动刷新好友列表。

一个基于 SwiftUI + Core Data 的本地聊天应用 Demo（macOS / iOS）。

## 功能

- **注册与登录** — 用户名 + 密码注册/登录，SHA-256 密码哈希，首启自动创建 admin 账号
- **会话列表** — 侧边栏展示所有对话，区分好友列表与会话列表，支持最近消息预览、选中态高亮
- **添加好友** — 输入用户名/ID 双向添加好友，自动创建私聊会话
- **创建群聊** — 填写群名称、从好友列表选择成员，创建后显示群聊标签
- **邀请进群** — 群聊头部邀请按钮，弹窗从好友列表选择用户加入
- **聊天界面** — 消息气泡列表，己方消息右对齐蓝色气泡、对方消息左对齐灰色气泡并显示发送者名称
- **消息持久化** — 消息实时写入 Core Data，重启后历史记录完整恢复
- **跨用户数据共享** — 同一份数据库文件，通过记录归属和成员关系实现数据隔离与会话共享

## 项目结构

```
Chat/
├── ChatApp.swift                     # App 入口，初始化全局 Store
├── ContentView.swift                 # 根视图，根据登录状态切换
├── LoginView.swift                   # 登录 / 注册页面
├── MainView.swift                    # 主页面（NavigationSplitView）
├── SidebarView.swift                 # 侧边栏（好友列表 + 会话列表 + 工具栏）
├── ConversationView.swift            # 聊天页面（协调头部/消息/输入）
├── ConversationViews/
│   ├── HeaderView.swift              # 会话头部（头像、名称、群聊标识、邀请按钮）
│   ├── ChatMessageView.swift         # 消息气泡列表（己方/对方差异化样式）
│   ├── MessageInputView.swift        # 消息输入框
│   ├── AddFriendView.swift           # 添加好友弹窗
│   ├── CreateGroupView.swift         # 创建群聊弹窗
│   └── InviteUserView.swift          # 邀请用户进群弹窗
└── Models/
    ├── ChatPersistence.swift         # Core Data 持久化层（数据模型 + 控制器）
    ├── Conversation.swift            # 会话 & 消息内存模型
    ├── Store.swift                   # 全局状态管理 + 业务逻辑
    └── User.swift                    # 用户模型
```

## 技术栈

- **SwiftUI** — 声明式 UI，NavigationSplitView 三栏导航
- **Core Data** — 程序化 NSManagedObjectModel（无 .xcdatamodeld），轻量迁移
- **MVVM** — ObservableObject + @Published + @EnvironmentObject
- **CryptoKit** — SHA-256 密码哈希
- **Target** — macOS 14.1+ / iOS 17.5+

## 后端设计

### 架构

无远程后端，全部数据存储在本地 Core Data 中。两个独立的持久化容器：

| 容器 | 文件 | 用途 |
|------|------|------|
| `ChatAuthPersistenceController` | `ChatAuth.sqlite` | 用户账户（登录/注册认证） |
| `ChatDataPersistenceController` | `ChatData.sqlite` | 业务数据（会话/消息/成员/联系人） |

### Core Data 实体

| 实体 | 属性 | 说明 |
|------|------|------|
| `UserAccountRecord` | userID, username, passwordHash, displayName, avatar, createdAt, lastLoginAt | 用户账户，username 唯一约束 |
| `ConversationRecord` | recordID, kind, title, avatar, lastMessagePreview, lastMessageAt, directKey, createdAt | 会话（direct / group），recordID 唯一约束 |
| `MessageRecord` | messageID, conversationID, senderID, content, messageType, sentAt | 消息，messageID 唯一约束 |
| `ConversationMemberRecord` | recordID, conversationID, userID, role, joinedAt | 会话成员，conversationID+userID 联合唯一约束 |
| `ContactRecord` | recordID, ownerUserID, peerUserID, peerUsername, peerDisplayName, peerAvatar, createdAt | 联系人，ownerUserID+peerUserID 联合唯一约束 |

### 核心业务流程

**添加好友：**
1. 当前用户和目标用户各保存一条 `ContactRecord`（双向好友）
2. 创建一条 `ConversationRecord`（kind = "direct"），存入 `directKey`（`minID:maxID`）
3. 双方各写入一条 `ConversationMemberRecord`

**创建群聊：**
1. 创建 `ConversationRecord`（kind = "group"）
2. 创建者为 owner，其余成员为 member，各写入一条 `ConversationMemberRecord`

**发送消息：**
1. 写入 `MessageRecord`
2. 更新 `ConversationRecord` 的 `lastMessagePreview` 和 `lastMessageAt`

**数据加载：**
- 查询 `ConversationMemberRecord` 获取用户参与的所有会话 ID
- 通过会话 ID 查询 `ConversationRecord`、`MessageRecord`、成员列表
- 私聊会话加载时通过 `directKey` 解析对方用户信息覆盖标题和头像

### 跨实例实时更新

多个 app 进程共享同一份 `ChatData.sqlite` 文件时，一个进程的写入操作对其他进程不可见。通过以下机制实现自动刷新：

1. 启用 Core Data 的 `NSPersistentHistoryTracking` 追踪所有写入操作
2. 启用 `NSPersistentStoreRemoteChangeNotification` 跨进程通知
3. 收到通知后刷新托管对象上下文，通过 `onRemoteChange` 回调通知 `Store`
4. `Store` 重新加载当前用户的会话列表、消息和联系人，保持现有 `Conversation` 对象引用以维持 UI 绑定

无需重登即可看到其他实例发送的消息。


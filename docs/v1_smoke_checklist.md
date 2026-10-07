# BiteSync V1 smoke checklist

目标用时：15–25 分钟。使用两个普通测试账号 A/B；删号步骤使用可丢弃账号。

- [ ] 冷启动显示 Login；登录后新账号进入 Onboarding。
- [ ] 完成 Recommendation 或 Manual Goals，提交后进入 Home；杀掉并重开 App 不再进入 Onboarding。
- [ ] 新建一餐，确认 Today 名称/热量一致；编辑后 Today 与 Summary 更新；收藏后可复用。
- [ ] “今天也吃了”展开后能看到当天全量记录；删除测试餐后 Today、History、Summary 同步消失。
- [ ] A 创建邀请，B 加入；两端均显示 Connected 且没有 owner 差异。
- [ ] A 新建 personal 与 together meal；核对双方 Today/Summary 和 allocation，再编辑/删除当前 Pair meal。
- [ ] A、B 分别打开 Training，确认训练记录正常且互相隔离。
- [ ] 新增、编辑、删除 Weight；确认 Body currentWeight/BMI 立即刷新，Partner 无法看到 Body 数据。
- [ ] 修改 Nutrition goals；确认 Profile 与 Summary 使用新目标。
- [ ] End Pair；两端回到 Single，历史 shared meal 可读但 edit/delete/refine 不可用，allocation 保留。
- [ ] Logout 后回 Login；重新登录及 App relaunch 都能恢复合法 session。
- [ ] Connected 状态下用可丢弃账号执行 Delete Account；确认另一方账号、Meal、Training、Body 仍在且变为 Single。

失败时记录账号、时间、步骤、HTTP 状态（如可见）与截图；不要粘贴 token、cookie 或完整服务端响应。

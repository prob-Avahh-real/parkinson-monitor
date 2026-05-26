# 交付物清单

## 1. 产品体验链接及 AtomGit 地址

| 项目 | 状态 | 路径/链接 |
|------|------|-----------|
| AtomGit 主页 README | ✓ | `deliverables/ATOMGIT.md` |
| 体验链接 (本地) | ✓ | `git clone <repo> && flutter run` |
| 无需硬件体验路径 | ✓ | 手机传感器回退 + 模拟步态 |

**待完成**: 将仓库推送至 AtomGit 后更新实际 URL。

---

## 2. 产品 Demo 演示视频

| 项目 | 状态 | 路径 |
|------|------|------|
| 视频分镜脚本 | ✓ | `deliverables/VIDEO_SCRIPT.md` |
| 7 镜头 3 分钟剧本 | ✓ | 含时间码、字幕、特效说明 |
| 录制方法指南 | ✓ | QuickTime / scrcpy |
| 后期处理命令 | ✓ | ffmpeg 裁剪/字幕/压缩 |

**待完成**: 真机录屏 + 后期制作。

---

## 3. 产品页面及功能截图 (≥ 5 张, ≥ 720P)

| 截图 | 状态 | 路径 |
|------|------|------|
| 方案文档 | ✓ | `deliverables/SCREENSHOTS.md` |
| 01_home.png — 首页仪表盘 | ☐ | `screenshots/` |
| 02_device_scan.png — 设备扫描 | ☐ | `screenshots/` |
| 03_calibration.png — 传感器校准 | ☐ | `screenshots/` |
| 04_monitoring_normal.png — 实时监测(正常) | ☐ | `screenshots/` |
| 05_monitoring_alert.png — 实时监测(告警) | ☐ | `screenshots/` |

**待完成**: 在真机/模拟器上使用 `Cmd+S` 截图并放入 `screenshots/` 目录。

---

## 4. 产品后端截图

| 截图 | 状态 | 路径 |
|------|------|------|
| 方案文档 | ✓ | `deliverables/BACKEND.md` |
| 初始化 SQL 脚本 | ✓ | 见 BACKEND.md |
| backend_01_tables.png — 数据库表 | ☐ | `screenshots/` |
| backend_02_rls.png — RLS 策略 | ☐ | `screenshots/` |
| backend_03_query.png — SQL 查询 | ☐ | `screenshots/` |
| backend_04_api.png — API 文档 | ☐ | `screenshots/` |

**待完成**: 在 Supabase Dashboard 截图并打码敏感信息。

---

## 5. 附加交付物

| 项目 | 状态 | 路径 |
|------|------|------|
| 产品文档 (五维度) | ✓ | `PRODUCT.md` |
| README (项目首页) | ✓ | `README.md` |
| 源代码 (脱敏版) | ✓ | `lib/` |
| 单元测试 (35 通过) | ✓ | `test/` |
| flutter analyze (零 issue) | ✓ | — |

---

## 6. 三平台推送 (AtomGit + GitHub + GitLab)

| 项目 | 状态 | 路径 |
|------|------|------|
| Git 初始化 | ✓ | `.git/` (main 分支) |
| .gitignore | ✓ | `.gitignore` |
| CI 工作流 (GitHub Actions) | ✓ | `.github/workflows/ci.yml` |
| 三平台推送脚本 | ✓ | `scripts/push.sh` |

推送:
```bash
vim scripts/push.sh   # 编辑仓库 URL
bash scripts/push.sh  # 一键推送三平台
```

---

## 动作清单

- [ ] 编辑 `scripts/push.sh` 中的仓库 URL
- [ ] `bash scripts/push.sh`
- [ ] `flutter run` 真机运行 → 截图 + 录屏
- [ ] 5 张产品截图 → `deliverables/screenshots/`
- [ ] 4 张后端截图 → `deliverables/screenshots/`
- [ ] 3 分钟 Demo 视频 → 后期制作

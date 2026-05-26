# Parkinson Monitor — 产品文档索引

## 本地链接 (相对路径)

| 文档 | 链接 |
|------|------|
| 产品文档 (五维度) | [PRODUCT.md](PRODUCT.md) |
| 项目 README | [README.md](README.md) |
| 交付物清单 | [deliverables/CHECKLIST.md](deliverables/CHECKLIST.md) |
| 截图方案 | [deliverables/SCREENSHOTS.md](deliverables/SCREENSHOTS.md) |
| 视频分镜 | [deliverables/VIDEO_SCRIPT.md](deliverables/VIDEO_SCRIPT.md) |
| AtomGit 主页 | [deliverables/ATOMGIT.md](deliverables/ATOMGIT.md) |
| 后端文档 | [deliverables/BACKEND.md](deliverables/BACKEND.md) |

## 截图

| 截图 | 链接 |
|------|------|
| 01 首页 | [deliverables/screenshots/01_home.png](deliverables/screenshots/01_home.png) |
| 02 设备扫描 | [deliverables/screenshots/02_device_scan.png](deliverables/screenshots/02_device_scan.png) |
| 03 校准 | [deliverables/screenshots/03_calibration.png](deliverables/screenshots/03_calibration.png) |
| 04 监测 | [deliverables/screenshots/04_monitoring.png](deliverables/screenshots/04_monitoring.png) |
| 05 历史 | [deliverables/screenshots/05_history.png](deliverables/screenshots/05_history.png) |
| Demo 视频 | [deliverables/screenshots/demo.mp4](deliverables/screenshots/demo.mp4) |

## 脚本

| 脚本 | 链接 |
|------|------|
| 三平台推送 | [scripts/push.sh](scripts/push.sh) |
| 截图录屏 | [scripts/capture_all.sh](scripts/capture_all.sh) |
| Supabase 验证 | [scripts/backend_check.sh](scripts/backend_check.sh) |

## 产品体验链接

| 方式 | 链接/命令 |
|------|----------|
| 🌐 Web 版 (本地) | `cd build/web && python3 -m http.server 8080` → http://localhost:8080 |
| 🍎 iOS 模拟器 | `flutter run` |
| 📱 真机 | `flutter run -d <device_id>` |
| 🌍 GitHub Pages | https://YOUR_ORG.github.io/parkinson-monitor |

## 远程仓库 (推送后)

| 平台 | 链接 |
|------|------|
| GitHub | https://github.com/YOUR_ORG/parkinson-monitor |
| GitLab | https://gitlab.com/YOUR_ORG/parkinson-monitor |
| AtomGit | https://atomgit.com/YOUR_ORG/parkinson-monitor |

> 编辑 `scripts/push.sh` 填入实际仓库地址后 `bash scripts/push.sh` 一键推送。

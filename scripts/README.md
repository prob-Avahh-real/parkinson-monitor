# ParkinsonMonitor — 项目模块结构总览

```
parkinson-monitor/
│
├── lib/                               ← Flutter App（你的已有代码）
│   ├── core/
│   │   ├── utils/signal_processor.dart  ← FFT 引擎（保留为主 ML 的回退）
│   │   └── di/injection_container.dart  ← ✅ 已更新（ML + 用药模块注册）
│   │
│   ├── services/
│   │   ├── detection_engine.dart        ← ✅ 已更新（双引擎：ML 优先，FFT 回退）
│   │   ├── ml_model_service.dart        ← 🆕 TFLite 模型推理封装
│   │   ├── medication_service.dart      ← 🆕 用药记录 service
│   │   └── ...（其余 7 个 service 均不动）
│   │
│   ├── domain/entities/
│   │   ├── medication_record.dart       ← 🆕 用药记录实体
│   │   └── ...（其余 5 个 entity 均不动）
│   │
│   └── presentation/pages/
│       ├── medication_page.dart         ← 🆕 用药记录页面
│       ├── home_page.dart              ← ✅ 已更新（增加用药记录入口）
│       └── ...（其余 5 个页面均不动）
│
├── assets/models/
│   ├── fog_detector.tflite              ← 🏗 训练后生成（Colab 导出）
│   └── scaler_params.json              ← 🏗 训练后生成（标准化参数）
│
├── scripts/
│   │
│   ├── agent_service/                   ← 🆕 Agent 层（Python，独立部署）
│   │   ├── main.py                       ← 调度入口 + CLI
│   │   ├── config.py                     ← 环境变量配置
│   │   ├── supabase_client.py            ← Supabase 数据接入
│   │   ├── analysis_agent.py             ← LLM 分析 Agent（日/周/用药）
│   │   ├── guardrails.py                 ← 医疗安全过滤
│   │   ├── notification_service.py       ← 微信/日志推送
│   │   ├── report_enhancer.py            ← 增强版 PDF 报告
│   │   ├── requirements.txt             ← Python 依赖
│   │   ├── Dockerfile                    ← 容器部署
│   │   └── .env.example                  ← 环境变量模板
│   │
│   ├── training/
│   │   └── train_fog_model.ipynb        ← Colab 模型训练脚本
│   │
│   └── README.md
│
├── pubspec.yaml                         ← ✅ 已更新（+tflite_flutter, +assets）
└── ...
```

## 改动统计

| 类别 | 文件 | 说明 |
|------|------|------|
| 🆕 新增 Flutter 文件 | 4 个 | ml_model_service、medication_service、medication_record、medication_page |
| ✅ 修改 Flutter 文件 | 3 个 | detection_engine、injection_container、home_page、pubspec.yaml |
| 🆕 新增 Agent 服务 | 10 个 | Python 独立后端，和 Flutter App 解耦 |
| 🆕 新增训练脚本 | 1 个 | Colab Notebook |
| 🔁 不动 | 34 个 | 所有 UI、BLoC、数据层、BLE、GPS、PDF 等 |

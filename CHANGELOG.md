# 修改記錄

## 1.0.1 (2026-09-15)

- 新增 host-owned connection resolver，讓同一平台的多個帳號各自驗證與發送訊息。
- 將 bot connection 與 provider identity scope 分開，避免多 channel 身份誤綁。

## [0.20.0](https://github.com/etrex/kamigo/tree/0.20.0) (2021-04-04)
[完整修改記錄](https://github.com/etrex/kamigo/compare/0.19.0...0.20.0)

- 修復 [line-bot-sdk-ruby 1.19.0](https://github.com/line/line-bot-sdk-ruby/pull/220) 版更新，造成無法解析 line event 的問題
- 對 [line_controller](https://github.com/etrex/kamigo/blob/master/app/controllers/line_controller.rb) 重構，擷取出 Request Handler
- 在 [README](https://github.com/etrex/kamigo/blob/master/README.md#%E8%A8%88%E7%95%AB) 新增計畫細節

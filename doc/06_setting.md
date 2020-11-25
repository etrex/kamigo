# Webhook URL 設定 QA
## 如何設定開發環境網域？
1. 安裝 [ngrok](https://dashboard.ngrok.com/get-started)。

2. 在 bash 執行 ngrok 來獲得對應 `http://localhost:3000` 的網域。

```bash
$ ./ngrok http 3000
```

3. 將獲得的網域替換掉花刮號的部分後，填入 Webhook URL 欄位。（留意網域後是否有確實加上 `/line`）

```
https://{NGROK_HTTPS_DOMAIN}/line
```

4. 在 Messaging API 後台開啟 `Use webhook` 設定。

5. 另外開一個 bash 執行 `$ rails s`。

6. 點擊 `Verify` 按鈕發送一個 POST Request 確認設定是否成功。

## 重開 ngrok 後，Webhook URL 就失效了？
若你重新執行 ngrok，則 ngrok 會產生新的網域，你需要變更 LINE Bot 的 Webhook URL 和 LIFF app 的 Endpoint URL 為新的網域。

## 完成串接流程，但 Kamigo 沒有反應？
若 Webhook URL 和 `.env` 檔都設定完，Kamigo 仍沒有反應，請確認以下兩個設定：

- 確認你的網域是否正確。
- 確認 `Use webhook` 是否為開啟狀態。

## Rails 6 注意事項

若使用 ngrok 在本機開發時，需要在 `config/application.rb` 加入以下程式碼：

```ruby
...
module KamigoDemo
  class Application < Rails::Application
    ...
    config.hosts << "你的亂碼.ngrok.io"
  end
end
```

才能正常連線。

# LIFF 設定 QA
## 如何新增 LIFF？
由於 LIFF v2 改善，LINE 官方在 2020/02/05 [發布通知](https://developers.line.biz/zh-hant/news/2020/02/05/liff-channel-type/)，日後新增 LIFF 需到 LINE Login 的 LIFF 分頁新增，原先在 Messaging API 新增的 LIFF 還能繼續使用。

1. 在 LINE Login 後台新增 3 種不同 size 的 LIFF，新增完會各獲得一組 LIFF URL；若你在 Messaging API 有設定好的 LIFF，請參考下方設定修改 Endpoint URL。（留意網域後是否有確實加上 `/liff_entry`）

- Compact
  * LIFF app name: Compact
  * Size: Compact
  * Endpoint URL: https://你的網域/liff_entry

- Tall
  * LIFF app name: Tall
  * Size: Tall
  * Endpoint URL: https://你的網域/liff_entry

- Full
  * LIFF app name: Full
  * Size: Full
  * Endpoint URL: https://你的網域/liff_entry

2. 在 `.env` 檔中分別填入對應 size 的 3 個 LIFF URL。

- 於 Messaging API 所建立的 LIFF（v1）
```
LIFF_COMPACT=line://app/{FOR_COMPACT_LIFF_ID}
LIFF_TALL=line://app/{FOR_TALL_LIFF_ID}
LIFF_FULL=line://app/{FOR_FULL_LIFF_ID}
```

- 於 LINE Login 所建立的 LIFF（v2）
```
LIFF_COMPACT=https://liff.line.me/{FOR_COMPACT_LIFF_ID}
LIFF_TALL=https://liff.line.me/{FOR_TALL_LIFF_ID}
LIFF_FULL=https://liff.line.me/{FOR_FULL_LIFF_ID}
```

## LIFF Mode 設定

關於 [Behaviors from accessing the LIFF URL to opening the LIFF app](https://developers.line.biz/en/docs/liff/opening-liff-app/#redirect-flow)，也就是 LIFF Mode，在 kamigo 當中，預設採用 Concatenate Mode，如果你想要使用 Replace Mode（[即將在 2021/3/1 被移除](https://developers.line.biz/en/news/2020/11/20/discontinue-replace-mode-announcement/)）的話，可以透過指定環境變數(不限大小寫）來使用。

```
LIFF_MODE=replace
```


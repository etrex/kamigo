# 詳細的說明文件

[Kamigo 詳細說明](https://etrex.tw/kamigo/)

# Kamigo 簡介
Kamigo 是一個基於 Rails 的 Chatbot MVC Framework。

Kamigo 讓你開發 Chatbot 就跟開發網站一樣容易，甚至可以同時開發網站以及 Chatbot 介面，共用 Controller 和 Model，只需要針對 Chatbot 實作 View。

Kamigo 提供了重要的 generator，讓你開發聊天機器人時可以快的跟飛一樣。

以下將說明如何使用 Kamigo 來製作 Todo 的教學文件。

# 建立新的 rails 專案
將以下指令全部複製，直接貼到 bash 執行即可。

```bash
# 建立新專案
rails new kamigo_demo
# 進入專案
cd kamigo_demo
# 安裝套件
bundle add kamigo
bundle add dotenv-rails
# 建立設定檔
rails g kamigo:install
# 新增 resource controller
rails g scaffold todo name desc
rails db:create
rails db:migrate
```

# 設定首頁
在 `config/routes.rb` 當中加入首頁設定：

```
root to: "todos#index"
```

# 安裝 js 套件

若使用 Asset Pipeline（Rails 5），請在 `app/assets/javascripts/application.js` 當中

加入以下程式碼：

```
//= require kamiliff
```

或者加入以下程式碼：

```
/* kamiliff default behavior */
window.addEventListener("liff_ready", function(event){
  register_kamiliff_submit();
});

window.addEventListener("liff_submit", function(event){
  var json = JSON.stringify(event.detail.data);
  var url = event.detail.url;
  var method = event.detail.method;
  var request_text = method + " " + url + "\n" + json;
  liff_send_text_message(request_text);
});
```

若使用 Webpacker（Rails 6），請在 `app/javascript/packs/application.js` 當中

加入以下程式碼：

```
/* kamiliff default behavior */
window.addEventListener("liff_ready", function(event){
  register_kamiliff_submit();
});

window.addEventListener("liff_submit", function(event){
  var json = JSON.stringify(event.detail.data);
  var url = event.detail.url;
  var method = event.detail.method;
  var request_text = method + " " + url + "\n" + json;
  liff_send_text_message(request_text);
});
```

若使用 Importmap（Rails 7），請使用 kamigo 0.27.0 以上的版本，並且在 `app/javascript/application.js` 當中

加入以下程式碼：

```
/* kamiliff default behavior */
window.addEventListener("liff_ready", function(event){
  register_kamiliff_submit();
});

window.addEventListener("liff_submit", function(event){
  var json = JSON.stringify(event.detail.data);
  var url = event.detail.url;
  var method = event.detail.method;
  var request_text = method + " " + url + "\n" + json;
  liff_send_text_message(request_text);
});
```

這會影響 LINE Bot 在 LIFF 送出表單時的行為。

# 設定聊天機器人 Webhook URL
本文假設你已經有一個自己的聊天機器人，請將以下網址填入 LINE Bot 的 Webhook URL 欄位中：

```
https://你的網域/line
```

第一次開發 LINE Bot 的人可以服用此帖 [Webhook URL 設定 QA](/doc/07_setting.md#Webhook-URL-設定-QA)。

# 設定聊天機器人環境變數
請在專案根目錄下新增一個 `.env` 檔並且填入以下內容：

```
LINE_LOGIN_CHANNEL_ID=這裡填入你的 LINE_LOGIN_CHANNEL_ID
LINE_LOGIN_CHANNEL_SECRET=這裡填入你的 LINE_LOGIN_CHANNEL_SECRET

LINE_CHANNEL_SECRET=這裡填入你的 LINE_CHANNEL_SECRET
LINE_CHANNEL_TOKEN=這裡填入你的 LINE_CHANNEL_ACCESS_TOKEN
LIFF_COMPACT=這裡填入你的 COMPACT_LIFF_URL
LIFF_TALL=這裡填入你的 TALL_LIFF_URL
LIFF_FULL=這裡填入你的 FULL_LIFF_URL
```

- `LINE_LOGIN_CHANNEL_ID` 可以在 LINE LOGIN 後台的 Basic settings 分頁中找到。
- `LINE_LOGIN_CHANNEL_SECRET` 可以在 LINE LOGIN 後台的 Basic settings 分頁中找到。
- `LINE_CHANNEL_SECRET` 可以在 Messaging API 後台的 Basic settings 分頁中找到。
- `LINE_CHANNEL_ACCESS_TOKEN` 可以在 Messaging API 後台的 Messaging API 分頁中找到。
- `COMPACT_LIFF_URL`、`TALL_LIFF_URL` 和 `FULL_LIFF_URL` 需要到 LINE 後台的 LIFF 分頁新增後，即可獲得一組 LIFF URL。

# 進階設定

在 `config/initializers/kamigo.rb` 中，你可以自訂各種設定：

```ruby
Kamigo.setup do |config|
  # LINE Messaging API 設定
  # 預設會從環境變數讀取，但你也可以直接在這裡設定
  # config.line_messaging_api_channel_id = "your_channel_id"
  # config.line_messaging_api_channel_secret = "your_channel_secret"
  # config.line_messaging_api_channel_token = "your_channel_token"

  # 當使用者輸入不符合路由時的預設路徑和 HTTP 方法
  # config.default_path = "/"
  # config.default_http_method = "GET"

  # 當 Kamigo 不知道如何回應時，會回覆這個訊息
  # config.line_default_message = {
  #   type: "text",
  #   text: "Sorry, I don't understand your message."
  # }
  # 設為 nil 則不回覆訊息

  # 設定訊息處理器，可以自訂處理邏輯
  # config.line_event_processors = [
  #   EventProcessors::RailsRouterProcessor.new,
  #   EventProcessors::DefaultPathProcessor.new,
  #   EventProcessors::DefaultMessageProcessor.new
  # ]
end
```

# 自定義訊息處理器（Event Processor）

Kamigo 允許你自定義訊息處理器來處理 LINE 的訊息。每個處理器都需要實作 `process` 方法，該方法接收一個 `event` 參數並回傳處理結果。

以下是一個簡單的處理器範例：

```ruby
module Kamigo
  module EventProcessors
    class MyCustomProcessor
      # 處理器可以存取 request 物件
      attr_accessor :request
      
      def process(event)
        # event 物件包含以下資訊：
        # - event.platform_type    # 平台類型（例如：line）
        # - event.message         # 使用者發送的訊息
        # - event.platform_params # 平台相關的參數
        # - event.source_group_id # 群組 ID（如果是群組訊息）
        
        # 在這裡實作你的處理邏輯
        return nil if event.message != "hello"  # 返回 nil 表示不處理此訊息
        
        # 返回要回覆給使用者的訊息（支援 LINE Messaging API 的所有訊息格式）
        {
          type: "text",
          text: "Hello! 你好！"
        }
      end
    end
  end
end

# 在 config/initializers/kamigo.rb 中註冊你的處理器
Kamigo.setup do |config|
  config.line_event_processors = [
    # 你可以完全自定義處理器順序
    EventProcessors::MyCustomProcessor.new,
    EventProcessors::RailsRouterProcessor.new,
    EventProcessors::DefaultPathProcessor.new,
    EventProcessors::DefaultMessageProcessor.new
  ]
end
```

處理器會按照註冊順序依次處理訊息，直到某個處理器返回非 nil 的結果。這讓你可以：

1. 建立特定關鍵字的回應
2. 實作自定義的語意理解
3. 整合第三方 NLP 服務
4. 處理特殊類型的訊息（圖片、音訊等）
5. 實作多輪對話

Kamigo 預設的 LIFF Size 為 Compact，你也可以只新增 Compact LIFF URL。
詳細的 LIFF 設定說明可以服用此帖 [LIFF 設定 QA](/doc/07_setting.md#LIFF-設定-QA)。

至此串接完成。

# Rails 6 注意事項

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

# 實際使用
Kamigo 預設使用基本的語意理解模型，會將使用者輸入視為在瀏覽器網址上輸入文字，並且以 LINE Flex Message 來顯示對應的結果。

開啟 LINE 和聊天機器人說 `/`，就能看到首頁的樣子。

# 使用 kamigo 製作的聊天機器人
- [kamigo demo](https://github.com/etrex/kamigo_demo)
  <p><img width="100" height="100" src="/docs/images/kamigo_demo_qrcode.png"></p>
- [健身紀錄機器人: Muscle-Man](https://github.com/louis70109/muscle_man)
  <p><img width="100" height="100" src="https://camo.githubusercontent.com/b8c51b15b20b159d356245277d079c04482acc01/68747470733a2f2f692e696d6775722e636f6d2f7534547675676e2e706e67"></p>
- 守護寵物機器人
  <p><img width="100" height="100" src="/docs/images/pet_loved_qrcode.png"></p>

# 計畫
- 提供多種語意理解模型串接
  - DialogFlow
  - LUIS
- 網站使用者與聊天機器人使用者綁定
  - Devise
- Log / 錯誤追蹤
- 支援其他平台
  - Telegram
  - Facebook Messenger
  - Slack

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

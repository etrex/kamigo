# Kamigo 簡介

Kamigo 是一個基於 Rails 的 Chatbot MVC Framework。

Kamigo 讓你開發 Chatbot 就跟開發網站一樣容易，甚至可以同時開發網站以及 Chatbot 介面，共用 Controller 和 Model，只需要針對 Chatbot 實作 View。

Kamigo 提供了重要的 generator，讓你開發聊天機器人時可以快的跟飛一樣。

以下將說明如何使用 Kamigo 來製作 Todo 的教學文件。

# 建立新的 rails 專案
以下指令直接複製全部，直接貼到 bash 執行即可。

```bash
# 建立新專案
rails new kamigo_demo
# 進入專案
cd kamigo_demo
# 安裝套件
bundle add kamigo
bundle add dotenv-rails
# 新增 resource controller
rails g scaffold todo name desc
rails db:create
rails db:migrate
```

# 設定首頁
在 config/routes.rb 當中加入首頁設定：

```
root to: "todos#index"
```

# 安裝 js 套件
在 `app/assets/javascripts/application.js` 當中加入一行程式碼：

```
//= require kamiliff
```

# 設定聊天機器人環境變數
本文假設你已經有一個自己的聊天機器人，請在專案根目錄下新增一個 `.env` 檔並且填入以下內容：

```
LINE_CHANNEL_SECRET=這裡填入你的 LINE_CHANNEL_SECRET
LINE_CHANNEL_TOKEN=這裡填入你的 LINE_CHANNEL_TOKEN
LIFF_COMPACT=這裡填入你的 LIFF_COMPACT
LIFF_TALL=這裡填入你的 LIFF_TALL
LIFF_FULL=這裡填入你的 LIFF_FULL
```

你可以在你的 LINE 管理後台找到 LINE_CHANNEL_SECRET 和 LINE_CHANNEL_TOKEN。

而 LIFF_COMPACT、LIFF_TALL 和 LIFF_FULL 你必須到 LINE 的後台中的 Liff 分頁去新增，詳細說明請參考 [kamiliff_demo](https://github.com/etrex/kamiliff_demo)。

# 設定聊天機器人 webhook url

請將以下網址填入 LINE Bot 的 webhook url 欄位中：

```
https://你的網域/line
```

至此串接完成。

# 實際使用

Kamigo 預設使用基本的語意理解模型，會將使用者輸入視為在瀏覽器網址上輸入文字，並且以 LINE Flex Message 來顯示對應的結果。

只要和你的聊天機器人說 `/`，就能看見首頁的樣子。

# 使用 kamigo 製作的聊天機器人
- [kamigo demo](https://github.com/etrex/kamigo_demo)
  ![](https://qr-official.line.me/M/q1CAuLSnNo.png)
- [健身紀錄機器人: Muscle-Man](https://github.com/louis70109/muscle_man)
  ![](https://camo.githubusercontent.com/c0d2233e3182c822ffc0816fe0cbb5610fe67914/68747470733a2f2f692e696d6775722e636f6d2f4f7930423257326d2e706e67)

# 詳細的說明文件
- [Kamigo 架構概觀](/doc/01_intro.md)
- [Route 的使用說明](/doc/02_route.md)
- [Controller 的使用說明](/doc/03_controller.md)
- [View 的使用說明](/doc/04_view.md)
- [Form 的使用說明](/doc/05_form.md)

# 計畫
- 提供多種語意理解模型串接
- 網站使用者與聊天機器人使用者綁定
- 支援 Telegram
- 支援 Facebook Messenger

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

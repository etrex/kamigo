# Kamigo 架構概觀

## 設計理念

Kamigo 是基於 Rails 的 Chatbot MVC Framework，竭盡所能的將聊天機器人的開發與網站開發做對應，並且盡可能的使用 Rails 既有的功能來增加彈性。

在聊天機器人開發當中的「語意理解」是對應到網站開發當中的路由（Route）。

「對話管理」對應到 Controller 以及 Model。

而「語言生成」則是對應到 view。

使用 Kamigo，你可以同時開發 Chatbot 以及 Web，而且共用 Controller 以及 Model。

## 架構概觀

Kamigo 實作了接受 LINE Webhook 的 Controller 以及對應的 Route。

controller: [https://github.com/etrex/Kamigo/blob/master/app/controllers/line_controller.rb](https://github.com/etrex/Kamigo/blob/master/app/controllers/line_controller.rb)
routes: [https://github.com/etrex/Kamigo/blob/master/config/routes.rb](https://github.com/etrex/Kamigo/blob/master/config/routes.rb)

以上的程式碼使得 Kamigo 在接收到來自 Webhook 的訊息後，會將訊息用語意理解的方式轉換為（Intent）以及關鍵字（Entity），並且生成一個新的 Request 再發送給對應的 Controller Action，取得 Response 後，再使用 Reply API 將 Response 訊息回傳給用戶。

## webhook 設定

從 [routes.rb](https://github.com/etrex/Kamigo/blob/master/config/routes.rb) 當中可以看到這一行：

```
post 'line', to: 'line#entry'
```

表示網站會接受 POST 到 `/line` 的 Request，並且交給 line_controller 當中的 entry 方法來處理。

這表示你應該在你的 LINE Bot 設定 Webhook Url 為 `https://你的網域/line`。

## rails generator

在安裝 Kamigo 後，使用 `rails g scaffold` 可以生成 Kamigo 魔改後的 controller 以及 view。

以下簡單說明各項負責的功能。

## routes

Kamigo 沒有修改 rails routes 的實作。

line_controller 會讀取 LINE 訊息當中的文字訊息，並且嘗試理解文字訊息當中的意圖（intent）以及關鍵字（entity），也就是語意理解的部分，

目前僅實作了一個最基本的語意理解模型，直接假設用戶輸入的文字是網址來做解析，之後會支援各大語意理解平台的串接。

擷取出意圖以及關鍵字之後，會嘗試找到此意圖所對應的 controller action，並且將關鍵字作為 params 傳入此 action。

簡而言之，語意理解就像是在做 routes 的工作。

目前 Kamigo 支援在 routes 撰寫一些簡單的語意理解規則，比方說，你可以在你的專案當中的 routes.rb 寫入以下程式碼：

```ruby
get "目錄", to: 'home#menu'
```

當用戶在對 LINE Bot 發話時輸入「目錄」文字訊息時，就可以將 Request 交給 home_controller 當中的 menu 方法來處理。

詳細說明請參考 [route](/02_route.md)

## Render Format

當用戶在對 LINE Bot 發話時輸入「目錄」時，實際上，Kamigo 會生成一個 GET [https://你的網域/目錄.line](https://你的網域/目錄.line) 的 Request

網址當中的 .line 是在指定 render format，當一個 Request 的 Format 為 line 的時候，render engine 會去嘗試尋找 views 資料夾當中副檔名為 .line 的檔案。

你可以在 controller 當中透過 params[:format] 取得當下 Request 的 Format 為何。

## Controller

在 controller 你可以在 params 收到一些來自 Kamigo 的參數，用來做身分驗證或取得用戶所發出的關鍵字等。

詳細說明請參考 [controller](/03_controller.md)

## View

在 view 當中，直接輸出 LINE Message API 所需要的 json 即可。

使用 [Kamiflex]() 可以讓你輕鬆打造出 flex message。

詳細說明請參考 [view](/04_view.md)

## Form

目前 Kamigo 僅提供 LIFF 作為表單填寫的解決方案，日後有可能會加入對話式表單的填寫。

Kamigo 使用 [Kamiliff]() 來製作 LIFF，你可以在 controller 就取得用戶身分的參數。

詳細說明請參考 [form](/06_form.md)

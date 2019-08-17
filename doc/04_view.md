# View 的使用說明

在 view 當中，你可以根據不同的通訊平台，去製作對應的回覆內容。

Kamigo 會根據目前的平台，選擇對應的 render format，以 LINE 來說就會是 .line。

由於 Kamigo 目前只支援 LINE 通訊平台，因此目前只有 .line 可以使用。

舉例來說，如果你在 `config/routes.rb` 寫入以下程式：

```ruby
get "目錄", to: 'home#index'
```

而且你有 `app/controllers/home_controller` 內容如下：

```ruby
class HomeController < ApplicationController
end
```

即表示你應該要在 `app/views/home/index.line` 或者 `app/views/home/index.line.erb` 或者 `app/views/home/index.line.jbuilder` 來寫你的回覆訊息。

比方說，你可以在 `app/views/home/index.line` 輸入以下訊息：

```ruby
{
  "type": "text",
  "text": "hello, world"
}
```

或者你可以在 `app/views/home/index.line.erb` 輸入以下訊息：

```ruby
<%= raw {
  type: "text",
  text: "hello, world"
}.to_json %>
```

或者你可以在 `app/views/home/index.line.jbuilder` 輸入以下訊息：

```ruby
json.type "text"
json.text "hello, world"
```

最終都會產生出一樣的 json，也就是 [LINE Messaging API] 所要求的格式：

```ruby
{
  "type": "text",
  "text": "hello, world"
}
```